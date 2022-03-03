//
//  ViewController.swift
//  TravelBook
//
//  Created by ferhatiltas on 3.03.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    
    var locationManager = CLLocationManager() // kullanicinin konumunu alacaz
    var chosenLatitude = Double()
    var chosenLongtitude = Double()
    var selectedTitle = ""
    var selectedTitleID : UUID?
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // lokasyonu en iyi, keskin sekilde alsin ama bu pili daha fazla tuketir
        locationManager.requestWhenInUseAuthorization() // uygulama kullandiginda konumu al
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
//        gestureRecognizer.minimumPressDuration = 3 // saniye boyunca uzun basarsa
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != ""{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0{
                    for result in results as! [NSManagedObject]{
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                        }
                        if let subTitle = result.value(forKey: "subtitle") as? String{
                            annotationSubtitle = subTitle
                        }
                        if let latitude = result.value(forKey: "latitude") as? Double{
                            annotationLatitude = latitude
                        }
                        if let longitude = result.value(forKey: "longitude") as? Double{
                            annotationLongitude = longitude
                        }
                        let annotation = MKPointAnnotation() // mapkit te ilgili verileri gostermek icin
                        annotation.title = annotationTitle
                        annotation.subtitle = annotationSubtitle
                        let coordinate = CLLocationCoordinate2DMake(annotationLatitude, annotationLongitude)
                        annotation.coordinate = coordinate
                        mapView.addAnnotation(annotation) // verilen verileri map de goster
                        nameTextField.text = annotationTitle
                        commentTextField.text = annotationSubtitle
                        
                        locationManager.stopUpdatingLocation()
                                                                
                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        let region = MKCoordinateRegion(center: coordinate, span: span)
                        mapView.setRegion(region, animated: true)
                    }
                }
             
            }catch{
                
            }
        }else{
            
        }
    }
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{ // uzun tiklama basladiysa
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)//kullanici konumunu al kordinatlara cevir
            chosenLatitude = touchedCoordinates.latitude
            chosenLongtitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameTextField.text // properties
            annotation.subtitle = commentTextField.text
            self.mapView.addAnnotation(annotation) // haritada uzun tiklanilan yere pin ekleyecegiz
            
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // guncellenen konumlari dizi icinde verecek
        if selectedTitle == ""{
            let location = CLLocationCoordinate2DMake(locations[0].coordinate.latitude, locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // zoomlamaya yarar deger azaldıkca zoomlama artacak
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true) // acilir acilmaz konumunu alip oraya zoomlayacak
        }

    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // pinin uzerine button ekleme button ile birlikte kendi konumunla pin arasinda navigasyon olusturma
        
        if annotation is MKUserLocation{// kendi yerini pin ile gosterme
            return nil
        }
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // pinin uzerinde cikan buttona tikladiginda
        if selectedTitle != ""{
            var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placeMArks, error in
                
                if let placeMark = placeMArks{
                if placeMark.count > 0{
                    let newPlaceMark = MKPlacemark(placemark: placeMark[0])
                    let item = MKMapItem(placemark: newPlaceMark)
                    item.name = self.annotationTitle
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving] // yontem araba
                    item.openInMaps(launchOptions: launchOptions)
                }
              }
            }
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        // veriler core dataya eklenilecek
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate // core data ya ulasabilmek icin
        let context = appDelegate.persistentContainer.viewContext
        let newPlace  = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameTextField.text, forKey: "title")
        newPlace.setValue(commentTextField.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongtitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
          try context.save()
            print("SUCCESS")
        }catch{
            print("ERROR")
        }
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)

        
    }
    

    
}
 
