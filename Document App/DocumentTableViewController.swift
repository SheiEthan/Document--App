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

func listFileInBundle() -> [DocumentFile] {
        
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
                    type: resourcesValues.contentType!.description)
                )
            }
        }
        return documentListBundle
    }

struct DocumentFile {
    var title: String
    var size: Int
    var imageName: String?
    var url: URL
    var type: String
    
    // Liste statique de documents pour les tests
    static let documents: [DocumentFile] = listFileInBundle()
}


extension Int {
    func formattedSize() -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(self))
    }
}


class DocumentTableViewController: UITableViewController, QLPreviewControllerDataSource, UIDocumentPickerDelegate {
    
    var previewItem: QLPreviewItem?
    var allDocuments: [DocumentFile] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addDocument))
        loadAllDocuments()
    }
    
    @objc func addDocument() {
        // Lancer le UIDocumentPicker
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item]) // Permet de sélectionner tous types de fichiers
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false // Pas de sélection multiple
        present(documentPicker, animated: true, completion: nil)
    }
    
    func copyFileToDocumentsDirectory(fromUrl url: URL) {
           let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
           let destinationUrl = documentsDirectory.appendingPathComponent(url.lastPathComponent)
           
           do {
               try FileManager.default.copyItem(at: url, to: destinationUrl)
                       
               let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
                       
                       
                   if let resources = resourceValues,
                      let name = resources.name, // Nom du fichier
                      let contentType = resources.contentType {
                       
                       let documentFile = DocumentFile(
                           title: name,
                           size: Int(resources.fileSize ?? 0),
                           imageName: nil,
                           url: destinationUrl,
                           type: contentType.description
                       )
                       allDocuments.append(documentFile)
                   } else {
                       print("Erreur: Les propriétés du fichier ne sont pas accessibles.")
                   }
           } catch {
               print(error)
           }
       }
    
    func listFileInDocumentsDirectory() -> [DocumentFile] {
        // Obtenir le chemin du répertoire Documents
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileManager = FileManager.default
        var documentList = [DocumentFile]()

        do {
            // Obtenir tous les fichiers du répertoire
            let fileUrls = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
            
            for fileUrl in fileUrls {
                // Récupérer les propriétés des fichiers
                let resourceValues = try fileUrl.resourceValues(forKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
                
                documentList.append(DocumentFile(
                    title: resourceValues.name ?? "Fichier inconnu",
                    size: resourceValues.fileSize ?? 0,
                    imageName: nil, // Pas d'image par défaut
                    url: fileUrl,
                    type: resourceValues.contentType?.description ?? "Type inconnu"
                ))
            }
        } catch {
            print("Erreur lors de la lecture des fichiers dans Documents : \(error.localizedDescription)")
        }

        return documentList
    }
    
    func loadAllDocuments() {
        // Charger les fichiers du bundle
        let bundleDocuments = listFileInBundle()

        // Charger les fichiers du répertoire Documents
        let documentDirectoryFiles = listFileInDocumentsDirectory()

        // Fusionner les fichiers dans la DataSource
        allDocuments = bundleDocuments + documentDirectoryFiles

        // Recharger la TableView
        tableView.reloadData()
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileUrl = urls.first else { return }
        copyFileToDocumentsDirectory(fromUrl: selectedFileUrl)

        // Mettre à jour la DataSource et recharger la TableView
        loadAllDocuments()
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allDocuments.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DocumentCell", for: indexPath)
                
        let document = allDocuments[indexPath.row]
                
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
    
    // Dans DocumentTableViewController

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let document = allDocuments[indexPath.row]
           instantiateQLPreviewController(withUrl: document.url)
       }

       // 2. Cette méthode permet de présenter le QLPreviewController
    func instantiateQLPreviewController(withUrl url: URL) {
       let previewController = QLPreviewController()
       previewController.dataSource = self  // Assigner le datasource à self
        previewItem = url as QLPreviewItem
       navigationController?.pushViewController(previewController, animated: true)
   }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1 // Nous ne présentons qu'un seul fichier à la fois
        }

        // Cette méthode retourne l'élément à asfficher
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            // Retourner l'item QuickLook, qui est simplement l'URL du fichier
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

