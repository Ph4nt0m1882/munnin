use crate::api::models::{Page, PageMetadata, TreeNode, WikiAnchor};
use chrono::Utc;
use std::fs;
use std::path::Path;

pub fn init_wiki(root_path: String, title: String) -> anyhow::Result<()> {
    let root = Path::new(&root_path);
    if !root.exists() {
        fs::create_dir_all(root)?;
    }
    let anchor_path = root.join(".crow");
    let anchor = WikiAnchor {
        title,
        version: "1.0".to_string(),
        created_at: Some(Utc::now().timestamp()),
    };
    let content = serde_yaml::to_string(&anchor)?;
    fs::write(anchor_path, content)?;
    Ok(())
}

pub fn read_anchor(root_path: String) -> anyhow::Result<WikiAnchor> {
    let anchor_path = Path::new(&root_path).join(".crow");
    let content = fs::read_to_string(anchor_path)?;
    let anchor: WikiAnchor = serde_yaml::from_str(&content)?;
    Ok(anchor)
}

pub fn scan_directory(root_path: String) -> anyhow::Result<TreeNode> {
    let root = Path::new(&root_path);
    scan_dir_recursive(root, root)
}

fn scan_dir_recursive(path: &Path, root: &Path) -> anyhow::Result<TreeNode> {
    let mut children = Vec::new();
    let name = path
        .file_name()
        .unwrap_or_default()
        .to_string_lossy()
        .to_string();
    let rel_path = path
        .strip_prefix(root)?
        .to_string_lossy()
        .to_string()
        .replace("\\", "/");

    if path.is_dir() {
        for entry in fs::read_dir(path)? {
            let entry = entry?;
            let entry_path = entry.path();
            let file_name = entry.file_name().to_string_lossy().to_string();

            // Ignore hidden files like .git, .crow, etc.
            if file_name.starts_with('.') {
                continue;
            }

            if entry_path.is_dir() {
                if let Ok(node) = scan_dir_recursive(&entry_path, root) {
                    children.push(node);
                }
            } else if entry_path.extension().and_then(|s| s.to_str()) == Some("md") {
                let is_dir = false;
                children.push(TreeNode {
                    name: file_name.replace(".md", ""),
                    path: entry_path
                        .strip_prefix(root)?
                        .to_string_lossy()
                        .to_string()
                        .replace("\\", "/"),
                    is_directory: is_dir,
                    children: Vec::new(),
                });
            }
        }
    }

    // Sort: directories first, then alphabetically
    children.sort_by(|a, b| {
        b.is_directory
            .cmp(&a.is_directory)
            .then(a.name.cmp(&b.name))
    });

    Ok(TreeNode {
        name: if rel_path.is_empty() {
            "Root".to_string()
        } else {
            name
        },
        path: rel_path,
        is_directory: true,
        children,
    })
}

pub fn read_page(root_path: String, rel_path: String) -> anyhow::Result<Page> {
    let file_path = Path::new(&root_path).join(&rel_path);
    let content = fs::read_to_string(file_path)?;

    // Parse Frontmatter
    let mut metadata = PageMetadata {
        title: Path::new(&rel_path)
            .file_stem()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string(),
        tags: vec![],
        created_at: None,
        updated_at: None,
    };
    let mut markdown_content = content.clone();

    if content.starts_with("---\n") || content.starts_with("---\r\n") {
        if let Some(end) = content[4..].find("\n---") {
            let yaml_str = &content[4..end + 4];
            if let Ok(parsed_meta) = serde_yaml::from_str::<PageMetadata>(yaml_str) {
                metadata = parsed_meta;
            }
            // Add + 4 for "\n---" and + 1 for newline after that
            let end_idx = end + 8;
            if end_idx < content.len() {
                markdown_content = content[end_idx..].trim_start().to_string();
            } else {
                markdown_content = String::new();
            }
        }
    }

    Ok(Page {
        path: rel_path,
        metadata,
        content: markdown_content,
    })
}

pub fn write_page(root_path: String, rel_path: String, page: Page) -> anyhow::Result<()> {
    let file_path = Path::new(&root_path).join(&rel_path);
    if let Some(parent) = file_path.parent() {
        fs::create_dir_all(parent)?;
    }

    let mut updated_meta = page.metadata;
    updated_meta.updated_at = Some(Utc::now().timestamp());

    let yaml_str = serde_yaml::to_string(&updated_meta)?;
    let final_content = format!("---\n{}---\n\n{}", yaml_str.trim(), page.content);

    fs::write(file_path, final_content)?;
    Ok(())
}
