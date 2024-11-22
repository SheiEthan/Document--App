//
//  DocumentTableViewController.swift
//  Document App
//
//  Created by Ethan TILLIER on 11/18/24.
//

import UIKit
import Foundation
import QuickLook
import UniformTypeIdentifiers


struct DocumentFile {
    var title: String
    var size: Int
    var imageName: String?
    var url: URL
    var type: String
    
    static func listFileInBundle() -> [DocumentFile] {
        let fm = FileManager.default
        let path = Bundle.main.resourcePath!
        let items = try! fm.contentsOfDirectory(atPath: path)
        var documentListBundle = [DocumentFile]()
        for item in items {
            if !item.hasSuffix("DS_Store") && item.hasSuffix(".jpg") {
                let currentUrl = URL(fileURLWithPath: path + "/" + item)
                let resourcesValues = try! currentUrl.resourceValues(forKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
                documentListBundle.append(DocumentFile(
                    title: resourcesValues.name!,
                    size: resourcesValues.fileSize ?? 0,
                    imageName: item,
                    url: currentUrl,
                    type: resourcesValues.contentType!.description
                ))
            }
        }
        return documentListBundle
    }

    static func listFileInDocumentsDirectory() -> [DocumentFile] {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileManager = FileManager.default
        var documentList = [DocumentFile]()
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
            for fileUrl in fileUrls {
                let resourceValues = try fileUrl.resourceValues(forKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
                documentList.append(DocumentFile(
                    title: resourceValues.name ?? "Fichier inconnu",
                    size: resourceValues.fileSize ?? 0,
                    imageName: nil,
                    url: fileUrl,
                    type: resourceValues.contentType?.description ?? "Type inconnu"
                ))
            }
        } catch {
            print("Erreur lors de la lecture des fichiers dans Documents: \(error.localizedDescription)")
        }
        return documentList
    }
}

// Extension pour formater les tailles de fichiers en format lisible
extension Int {
    func formattedSize() -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(self))
    }
}

class DocumentTableViewController: UITableViewController, UISearchBarDelegate, QLPreviewControllerDataSource, UIDocumentPickerDelegate {

    var previewItem: QLPreviewItem?
    var allDocuments: [[DocumentFile]] = [[], []]
    var filteredDocuments: [[DocumentFile]] = [[], []]
    var isSearchActive = false
    var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuration de la barre de recherche
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Rechercher par titre"
        
        // Ajouter la Search Bar en tant que header de la tableView
        self.tableView.tableHeaderView = searchBar
        
        // Modifier la taille du header pour donner de l'espace à la barre de recherche
        let headerHeight: CGFloat = 44.0 // Hauteur de la Search Bar
        var frame = searchBar.frame
        frame.size.height = headerHeight
        searchBar.frame = frame
        self.tableView.tableHeaderView = searchBar
        
        // Bouton d'ajout de document
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addDocument))
        
        loadAllDocuments()
    }

    func filterDocuments(by searchText: String) {
        if searchText.isEmpty {
            filteredDocuments = allDocuments
        } else {
            filteredDocuments = allDocuments.map { section in
                section.filter { document in
                    document.title.lowercased().contains(searchText.lowercased())
                }
            }
        }
        tableView.reloadData()
    }

    // Gestion de l'événement lorsque le texte de la barre de recherche change
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterDocuments(by: searchText)
    }

    // Action de suppression de la recherche
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        filterDocuments(by: "")
        searchBar.resignFirstResponder()
    }

    // Fonction pour charger les documents
    func loadAllDocuments() {
        let bundleDocuments = DocumentFile.listFileInBundle()
        let documentDirectoryFiles = DocumentFile.listFileInDocumentsDirectory()
        
        // Stocke les fichiers dans les sections appropriées
        allDocuments[0] = bundleDocuments
        allDocuments[1] = documentDirectoryFiles
        
        filteredDocuments = allDocuments // Initialisation des documents filtrés à la totalité
        tableView.reloadData()
    }

    // Ajout d'un document via le document picker
    @objc func addDocument() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }

    func copyFileToDocumentsDirectory(fromUrl url: URL) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        
        do {
            try FileManager.default.copyItem(at: url, to: destinationUrl)
            
            let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
            
            if let resources = resourceValues,
               let name = resources.name,
               let contentType = resources.contentType {
                
                let documentFile = DocumentFile(
                    title: name,
                    size: Int(resources.fileSize ?? 0),
                    imageName: nil,
                    url: destinationUrl,
                    type: contentType.description
                )
                allDocuments[1].append(documentFile)
            } else {
                print("Erreur: Les propriétés du fichier ne sont pas accessibles.")
            }
        } catch {
            print(error)
        }
    }

    // MARK: - Table View DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDocuments[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell", for: indexPath)
        
        let document = filteredDocuments[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = document.title
        cell.detailTextLabel?.text = "Size: \(document.size.formattedSize())"
        
        let arrowIcon = UIImage(systemName: "chevron.right")
        cell.accessoryView = UIImageView(image: arrowIcon)
        
        if let imageName = document.imageName {
            cell.imageView?.image = UIImage(named: imageName)
        } else {
            cell.imageView?.image = UIImage(systemName: "doc.text")
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let document = filteredDocuments[indexPath.section][indexPath.row]
        instantiateQLPreviewController(withUrl: document.url)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Bundle"
        case 1:
            return "Importés"
        default:
            return nil
        }
    }

    // MARK: - QuickLook

    func instantiateQLPreviewController(withUrl url: URL) {
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewItem = url as QLPreviewItem
        navigationController?.pushViewController(previewController, animated: true)
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return previewItem!
    }


    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

