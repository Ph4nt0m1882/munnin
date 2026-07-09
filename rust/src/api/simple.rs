#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

/// Initialise un nouveau wiki
/// Crée un dossier `name` dans `parent_path` et y ajoute le dossier caché `.crow`
#[flutter_rust_bridge::frb(sync)]
pub fn init_wiki(parent_path: String, name: String) -> Result<String, String> {
    let parent_dir = std::path::Path::new(&parent_path);
    let wiki_dir = parent_dir.join(&name);
    let crow_file = wiki_dir.join(format!("{}.crow", name));

    // Vérifie si le dossier du wiki existe déjà
    if wiki_dir.exists() {
        return Err(format!("Le dossier '{}' existe déjà dans cet emplacement.", name));
    }

    // Crée le dossier du wiki et tous les parents nécessaires
    if let Err(e) = std::fs::create_dir_all(&wiki_dir) {
        return Err(format!("Impossible de créer le dossier du wiki: {}", e));
    }

    // Crée le fichier caché .crow à l'intérieur
    if let Err(e) = std::fs::File::create(&crow_file) {
        return Err(format!("Impossible de créer le fichier d'ancrage .crow: {}", e));
    }

    // On pourrait ajouter des fichiers initiaux ici (ex: un index.md ou settings.json)
    
    // Retourne le chemin absolu du wiki fraîchement créé
    Ok(wiki_dir.to_string_lossy().into_owned())
}
