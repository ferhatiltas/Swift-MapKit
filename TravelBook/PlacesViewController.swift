//
//  PlacesViewController.swift
//  TravelBook
//
//  Created by ferhatiltas on 3.03.2022.
//

import UIKit
import CoreData
class PlacesViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var titleArray = [String]()
    var idArray = [UUID]()
    var chosenTitle = ""
    var chosenID : UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        getData()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClick))
        
        tableView.delegate = self
        tableView.dataSource = self

    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    @objc func getData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do{
            let results  = try context.fetch(request)
            if results.count > 0 {
                self.titleArray.removeAll()
                self.idArray.removeAll()
                for result in results as! [NSManagedObject] {
                    if let title = result.value(forKey: "title") as? String{
                    
                       self.titleArray.append(title)
                   }
                    if let id = result.value(forKey: "id") as? UUID{
                     
                        self.idArray.append(id)
                    }
                    tableView.reloadData()
                    
                }
            }
        }catch{
            print("ERROR")
        }
    }
    
    @objc func addButtonClick(){
        chosenTitle = ""
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = titleArray[indexPath.row]
        chosenID = idArray[indexPath.row]
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapVC" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedTitle = chosenTitle
            destinationVC.selectedTitleID = chosenID
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                       let context = appDelegate.persistentContainer.viewContext
                       let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
                       let idString = idArray[indexPath.row].uuidString
                       fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
                       fetchRequest.returnsObjectsAsFaults = false
                       do {
                       let results = try context.fetch(fetchRequest)
                           if results.count > 0 {
                               for result in results as! [NSManagedObject] {
                                   if let id = result.value(forKey: "id") as? UUID {
                                       if id == idArray[indexPath.row] {
                                           context.delete(result)
                                           titleArray.remove(at: indexPath.row)
                                           idArray.remove(at: indexPath.row)
                                           self.tableView.reloadData()
                                           do {
                                               try context.save()
                                           } catch {
                                               print("error")
                                           }
                                           break
                                       }
                                   }
                               }
                           }
                       } catch {
                           print("error")
                       }
                       
        }
    }
}
