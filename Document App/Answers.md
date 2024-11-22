#1-ENVIRONNEMENT

##Exercice 1

Les targets :

C'est les différentes configurations de construction et d'exécution d'une application. Ils définissent l'objectif de l'application.

Les fichiers de bases :

AppDelegate : Permet de lancer, d'arreter et de gérer l'application. 
ViewController : Gère les vues dans l'application.
SceneDelegate : Gère l'interface de l'application quand il y a plusieurs scene.

Le dossier Assets.xcassets :

Gère et stocke toutes les ressources visuelles de l'application.

Le storyboard :

Permet de créer l'interface graphique de l'application.

Un simulateur : 

Permet de tester l'application dans un environnement virtuel directement dans xcode (permet de tester l'application avant le déployement).

##Exercice 2 

Cmd + R : Sert a build le projet pour le compiler et exécuter le code.

Cmd + Shift + O : Ouvre un ficher dans le projet grace a la recherche.

Indenter le code automatiquement : Cmd + i

Commenter la selection : Cmd + /

##Exercice 3

Testé avec plusieurs iphone et des ipad.

#3-DELEGATION

##Exercice 1 

Propriété statique : On utilise les propriétés statiques quand l'on souhaite stocker des données dans une classe. Quand on a pas beson de répliquer ces données dans les instances.

##Exercice 2 

dequeueReusableCell : Important pour les performances de l'application car cela permet de réutiliser les cellules au lieu d'en recréer à chaque fois que la table est affiché sur l'application. Cela permet donc de ne pas mettre un gros temps de calcul à chaque fois.

#4-NAVIGATION

##Exercice 1

Que venons de faire en réalité ?

Nous venons de créer un système de navigation avec le titre de la page actuelle. 

NavigationController :

Gère une pile qui possède un ou plusieurs ViewControllers tout en affichant un seul ViewControllers. Gère la logique.

NavigationBar même chose que NavigationController ?

Ils ne sont pas pareil mais peuvent s'utiliser ensemble. NavigationBar est une barre qui permet d'afficher le titre de la page actuelle, les actions de navigations entre les vues, d'autres actions. Alors que NavigationController gère toutes les vues pour naviguer entre elles.

#5-BUNDLE

##Exercice 1 

<!-- fonction qui retourne un DocumentFile-->
func listFileInBundle() -> [DocumentFile] {
<!-- initialise l'emplacement a recherche par défaut-->
        let fm = FileManager.default
<!-- récupère le chemin du bundle de l'application-->
        let path = Bundle.main.resourcePath!
<!-- récupère tous les fichiers du repertoire-->
        let items = try! fm.contentsOfDirectory(atPath: path)
<!-- crée une liste de tous les documents -->
        var documentListBundle = [DocumentFile]()
<!-- pour tous les item dans la liste d'items-->
        for item in items {
<!-- si le fichier ne termine pas par "DS_Store" et termine par ".jpg"-->
            if !item.hasSuffix("DS_Store") && item.hasSuffix(".jpg") {
<!-- donne un url actuel qui est le chemin avec le nom de l'item a la fin-->
                let currentUrl = URL(fileURLWithPath: path + "/" + item)
<!-- donne a l'url actuelle des valeurs comme un type de contenu, un nom et une taille de fichier-->
                let resourcesValues = try! currentUrl.resourceValues(forKeys: [.contentTypeKey, .nameKey, .fileSizeKey])
<!-- ajoute a la liste documentListBundle un DocumentFile-->
                documentListBundle.append(DocumentFile(
<!-- donne au DocumentFile le nom de l'url actuelle grace a resourcesValues-->
                    title: resourcesValues.name!,
<!-- donne une taille de fichier et si il n'y en a pas donne 0-->
                    size: resourcesValues.fileSize ?? 0, 
<!-- le nom de l'image est le nom de l'item-->
                    imageName: item,
<!-- l'url est l'url actuelle-->
                    url: currentUrl,
<!-- donne un type-->
                    type: resourcesValues.contentType!.description)
                )
            }
        }
<!-- le retour de la fonction est la liste documentListBundle--> 
        return documentListBundle
    }

#6-ECRAN DETAIL

##Exercice 1

Segue : c'est un objet dans le storyboard qui permet de créer une transition entre deux pages.

##Exercice 2

Constraint : permet de créer une mise en page fléxible et adaptative. Permettent à l'interface de s'ajuster à différents types de périphériques et tailles d'écran.

Lien avec AutoLayout : Les constraints permettent de définir des règles de positionnement ou de dimensionnement pour les vues pour le système autoLayout. L'autoLayout c'est le système qui gère la disposition dynamique des éléments à l'écran.

#9-QLPREVIEW

Pourquoi serait-il plus pertinent de changer l'accessory de nos cellules pour un disclosureIndicator ?

Le disclosureIndicator est un indicateur visuel qui permet à l'utilisateur de savoir que un élément est intéractif. Il est donc pertinent de l'utiliser pour indiquer qu'il y a une action de navigatoin ou alors pour une meilleure UX.

#10-IMPORTATION

Selector : Représente les noms de méthodes d'un objet ou d'une classe et qui sont utilisé pendant l'exécution du code.

.add : Permet d'ajouter des éléments ou de modifier des collections.

@objc devant la fonction ciblée par le selector : Utilisé pour communiquer avec les éléments qui utilisent Objective-C.

Ajouter plusieurs boutons dans la barre de navigation : Oui c'est possible. 
    let button1 = UIBarButtonItem(title: "Button 1", style: .plain, target: self, action: #selector(button1Tapped))
    let button2 = UIBarButtonItem(title: "Button 2", style: .plain, target: self, action: #selector(button2Tapped))
    let button3 = UIBarButtonItem(title: "Button 3", style: .plain, target: self, action: #selector(button3Tapped))
    navigationItem.rightBarButtonItems = [button1, button2, button3]
