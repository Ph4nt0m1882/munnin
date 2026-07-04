use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WikiAnchor {
    pub title: String,
    pub version: String,
    pub created_at: Option<i64>,
}

impl Default for WikiAnchor {
    fn default() -> Self {
        Self {
            title: "Mon Wiki".to_string(),
            version: "1.0".to_string(),
            created_at: None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PageMetadata {
    pub title: String,
    #[serde(default)]
    pub tags: Vec<String>,
    pub created_at: Option<i64>,
    pub updated_at: Option<i64>,
}

#[derive(Debug, Clone)]
pub struct Page {
    pub path: String, // Relative to the wiki root
    pub metadata: PageMetadata,
    pub content: String,
}

#[derive(Debug, Clone)]
pub struct TreeNode {
    pub name: String,
    pub path: String,
    pub is_directory: bool,
    pub children: Vec<TreeNode>,
}
