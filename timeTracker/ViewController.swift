//
//  ViewController.swift
//  timeTracker
//
//  Created by user158147 on 8/7/19.
//  Copyright © 2019 Johnathan Matodobra. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Parse
import UserNotifications

class ViewController: UIViewController, UITableViewDataSource {
   
    
    
    var data: [String] = []
    var timer = Timer()
    

    
    //Start Variables & Outlets for MapView & Address Label

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    
    //Create Global Variable for Previous Location to use elsewhere in code
    //Create Global PFObject array with the list of results
    
    var inOutResults:[PFObject]?
    var previousLocation:CLLocation?
    
    //Location Manager is the base call to utilize location functions
    
    let locationManager = CLLocationManager()
    
    //Region In Meters is the size of the region on the map for consistency. Needs to be double
    let regionInMeters:Double = 1000
    
    @IBOutlet weak var tableView: UITableView!
    
    //View Did Load calls functions when the view loads before shown. Want to check to see if Location services are enabled before the view loads else mapping functions will not work and will display errors.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        for i in 0...1000 {
            data.append("\(i)")
        }
        
        checkLocationServices()
        
        updateTableView()
        
        tableView.dataSource = self
     
    }
    
    func scheduledTimerWithTimeInterval() {
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: Selector("updateTableView"), userInfo: nil, repeats: true)
    }
    func updateTableView() {
        var results = queryResults(clasName: "InOutStatus")
        
        if results.count != inOutResults?.count {
            inOutResults = results
            print(inOutResults)
        }
        
    }
    
    func displayNotification(title: String, body:String) {
        
        let center = UNUserNotificationCenter.current()
        
        
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.threadIdentifier = "local-notifications temp"
        
        let date = Date(timeIntervalSinceNow: 1)
        let dateComponents = Calendar.current.dateComponents([.year, .month, .hour, .day, .minute, .second], from: date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: "content", content: content, trigger: trigger)
        
        center.add(request) { (error) in
            if error != nil {
                print(error)
            } else {
                print(request)
            }
        }
        
        
    }
    
    //This function creates an easier way to get results so that the code doesn't have to be repeated over and over again.
    func queryResults (clasName: String) -> [PFObject] {
        let query = PFQuery(className: clasName)
        
        do {
            let results: [PFObject] = try query.findObjects()
            return results

        } catch {
            return error as! [PFObject]
        }
        
    }
    
    func updateTime() {
        var query = PFQuery(className: "InOutStatus")
        query.findObjectsInBackground { (results, error) in
            if (error != nil) {
                print(error)
            } else if results!.count > 0 {
            for result in results! {
                var objectId = result.objectId ?? ""
                var date = result["date"] ?? ""
                var outTime = result["outTime"] ?? ""
                var inDate = result["inDate"] ?? ""
                var inTime = result["inTime"] ?? ""
                var reason = result["reason"] ?? ""
                print("Checking for empty in time")
                print("Date \(date) \(outTime) & \(inTime)")
                
                if outTime as! String != "" && inTime as! String == "" {

                    guard let updateResultId = result.objectId else { return }
                    let date = Date()
                    var currentDate = self.getCurrentDate(fromDate: date)
                    var currentTime = self.getCurrentTime(fromTime: date)
                    
                    result["inTime"] = currentTime
                    result["inDate"] = currentDate
                    
                    result.saveInBackground { (success, error) in
                        
                        if success {
                            print("Successfully update Result intime & indate")
                        } else {
                            print(error)
                        }
                    
                    }
                }
            }
                
        }
    }
}
    
    
    func createTime() {
        var parseObject = PFObject(className:"InOutStatus")
        
        var date = Date()
        var currentDate = getCurrentDate(fromDate: date)
        var currentTime = getCurrentTime(fromTime: date)
        
        
        parseObject["unit"] = "6301"
        parseObject["outTime"] = currentTime
        parseObject["reason"] = "testing"
        parseObject["date"] = currentDate
        
        // Saves the new object.
        parseObject.saveInBackground {
            (success: Bool, error: Error?) in
            if (success) {

                print("successfully updated exit station time")
            } else {
                // There was a problem, check error.description
            }
        }
    }
    
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    
    func checkLocationServices() {
        
        if CLLocationManager.locationServicesEnabled() {
                setupLocationManager()
            checkLocationAuthorization()
            
            
        } else {
            //Show alert telling user to turn this on
        }
    }
    
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            
            break
        case .denied:
            break
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            break
        case .restricted:
            break
        case .authorizedAlways:
           startTrackingUserLocation()
        
        }
    }

    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let  region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func startTrackingUserLocation() {
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
        regionMonitoring()
    }
    
    func getCurrentDate(fromDate: Date) -> String {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .medium
        
        dateFormatter.timeStyle = .none
        
        return dateFormatter.string(from: fromDate)
        
    }
    
    
    func getCurrentTime(fromTime: Date) -> String {
        
        let timeFormatter = DateFormatter()
        
        timeFormatter.dateStyle = .none
        
        timeFormatter.timeStyle = .medium
        
        let timeString = timeFormatter.string(from: fromTime)
        
        return timeString
    }
    
    


func numberOfSections(in tableView: UITableView) -> Int {
    return 1
}
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return inOutResults!.count
}
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        
        var reverseResults: [PFObject] = (inOutResults?.reversed())!
        let data = reverseResults[indexPath.row]
        let outTime = data["outTime"] as! String ?? ""
        let inTime = data["inTime"] as! String ?? ""
        let date = data["date"] as! String ?? ""


        let text = "\(outTime) - \(inTime)"
        
        cell?.textLabel?.text = text
        cell?.detailTextLabel?.text = date
        
        return cell!
    }

}
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //We will be back here
        guard let location = locations.last  else {return}
        let center = CLLocationCoordinate2D.init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //Will be back
        checkLocationAuthorization()
    }
    
    func getCenterLocation(for mapView:MKMapView) -> CLLocation {
        let latitude = previousLocation?.coordinate.latitude ?? mapView.centerCoordinate.latitude
        let longitude = previousLocation?.coordinate.longitude ?? mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    func regionMonitoring() {
        
        var slStation = CLLocationCoordinate2D.init(latitude: 42.4612109, longitude: -83.6557185)
        var region = MKCoordinateRegion(center: slStation, latitudinalMeters: 100, longitudinalMeters: 100)
        
        let monitorRegion = CLCircularRegion(center: slStation, radius: 100, identifier: "SL Station")
        
        locationManager.startMonitoring(for: monitorRegion)

        
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
      print("did exit region")
        let date = Date()
        var time = getCurrentTime(fromTime: date)
        displayNotification(title: "Left Station", body: "You left you station at \(time)")
        createTime()
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Arrived Station")
        let date = Date()
        var time = getCurrentTime(fromTime: date)
        displayNotification(title: "Arrived at Station", body: "You arrived to your station at \(time)")
        updateTime()
    }
    
    
   
    
    
    func postLocalNotifications(eventTitle:String){
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = eventTitle
        content.body = "You've entered a new region"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let notificationRequest:UNNotificationRequest = UNNotificationRequest(identifier: "Region", content: content, trigger: trigger)
        
        center.add(notificationRequest, withCompletionHandler: { (error) in
            if let error = error {
                // Something went wrong
                print(error)
            }
            else{
                print("added")
            }
        })
    }
    
    
}
    extension ViewController: MKMapViewDelegate {
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            
            let center = getCenterLocation(for: mapView)
            let geocoder = CLGeocoder()
            
            guard var previousLocation = self.previousLocation else { return }
            
            guard center.distance(from: previousLocation) > 50 else {
                    return
            }
            
            previousLocation = center
            
            geocoder.reverseGeocodeLocation(center) {[weak self] (placemarks, error) in
                
                guard let self = self else { return }
                
                if let _ = error {
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    return
                    
                }
                
                var streetNumber = placemark.subThoroughfare ?? ""
                var streetName = placemark.thoroughfare ?? ""
                
                DispatchQueue.main.async {
                    self.addressLabel.text = "\(streetNumber) \(streetName)"
                }
                
            }
        }
}
        


            

