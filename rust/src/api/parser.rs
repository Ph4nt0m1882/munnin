use flutter_rust_bridge::frb;
use pulldown_cmark::{Event, Parser, Tag, TagEnd};
use crate::api::models::{TextChunk, TextAttributes};

#[frb(sync)]
pub fn markdown_to_delta(markdown: String) -> Vec<TextChunk> {
    let parser = Parser::new(&markdown);
    let mut chunks = Vec::new();
    let mut current_attrs = TextAttributes::default();

    for event in parser {
        match event {
            Event::Start(tag) => match tag {
                Tag::Strong => current_attrs.bold = true,
                Tag::Emphasis => current_attrs.italic = true,
                Tag::Strikethrough => current_attrs.strikethrough = true,
                Tag::Heading { level, .. } => current_attrs.header = Some(level as u8),
                Tag::Link { dest_url, .. } => current_attrs.link = Some(dest_url.to_string()),
                _ => {}
            },
            Event::End(tag_end) => match tag_end {
                TagEnd::Strong => current_attrs.bold = false,
                TagEnd::Emphasis => current_attrs.italic = false,
                TagEnd::Strikethrough => current_attrs.strikethrough = false,
                TagEnd::Heading(_) => {
                    // Inject a newline at the end of a heading
                    chunks.push(TextChunk {
                        text: "\n".to_string(),
                        attributes: current_attrs.clone(),
                    });
                    current_attrs.header = None;
                }
                TagEnd::Link => current_attrs.link = None,
                TagEnd::Paragraph => {
                    // Inject a double newline at the end of a paragraph
                    chunks.push(TextChunk {
                        text: "\n\n".to_string(),
                        attributes: TextAttributes::default(),
                    });
                }
                _ => {}
            },
            Event::Text(text) => {
                chunks.push(TextChunk {
                    text: text.to_string(),
                    attributes: current_attrs.clone(),
                });
            }
            Event::Code(code) => {
                let mut attrs = current_attrs.clone();
                attrs.code = true;
                chunks.push(TextChunk {
                    text: code.to_string(),
                    attributes: attrs,
                });
            }
            Event::SoftBreak | Event::HardBreak => {
                chunks.push(TextChunk {
                    text: "\n".to_string(),
                    attributes: current_attrs.clone(),
                });
            }
            _ => {}
        }
    }

    chunks
}

#[frb(sync)]
pub fn delta_to_markdown(chunks: Vec<TextChunk>) -> String {
    let mut markdown = String::new();
    let mut prev_attrs = TextAttributes::default();

    for chunk in chunks {
        let attrs = &chunk.attributes;
        let mut text = chunk.text.clone();

        // Handle inline formatting changes (simpler version)
        // In a real robust implementation, we would need to carefully manage nesting, 
        // but for now we apply tags locally if they differ or just wrap the text.
        
        let mut prefix = String::new();
        let mut suffix = String::new();

        if attrs.header.is_some() && prev_attrs.header != attrs.header {
            let level = attrs.header.unwrap();
            prefix.push_str(&format!("{} ", "#".repeat(level as usize)));
        }

        if attrs.bold {
            prefix.push_str("**");
            suffix.push_str("**");
        }
        if attrs.italic {
            prefix.push_str("*");
            suffix.push_str("*");
        }
        if attrs.strikethrough {
            prefix.push_str("~~");
            suffix.push_str("~~");
        }
        if attrs.code {
            prefix.push_str("`");
            suffix.push_str("`");
        }

        if let Some(link) = &attrs.link {
            markdown.push_str(&format!("[{}]({})", text, link));
        } else {
            markdown.push_str(&format!("{}{}{}", prefix, text, suffix));
        }

        prev_attrs = attrs.clone();
    }

    // A more robust implementation would track opened tags and close them sequentially,
    // avoiding redundant `**bold** **bold**`.
    // The current version is basic and wraps every chunk individually.
    // For MVP, this is sufficient to prove the bidirectional concept.

    // Cleanup redundant newlines from wrapping if necessary
    markdown
}
