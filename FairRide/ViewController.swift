//
//  ViewController.swift
//  FairRide
//
//  Created by Stephen Fung on 8/7/18.
//  Copyright © 2018 Stephen Fung. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import UberCore
import UberRides
import LyftSDK

class ViewController: UIViewController{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pickUpLocationSearchBar: UISearchBar!
    @IBOutlet var locationResultTableView: UITableView!
    @IBOutlet weak var dropOffLocationSearchBar: UISearchBar!
    
    static var dropOffLocation = ""
    static var pickUpLocation = ""
    
    var locationManager = CLLocationManager()
    let completer = MKLocalSearchCompleter()
    var addresses = [String]()
    //TODO: DONT KEEP IT STATIC - just for testing purposes
    static var pickUpLocationSet = false
    
    static var distance = 0.0
    static var travelTime = 0
    static var publicTransportationTravelTime: Int?
    static var walkingTravelTime: Int?
    static var uberPrices: [PriceEstimate] = []
    static var uberTimes: [TimeEstimate] = []
    static var lyftPrices: [Cost] = []
    static var lyftTimes: [ETA] = []
    
    var dataRetrived = [false,false,false,false]
    
    var activeTextView = ""; //top for pickup location, buttom for destination
    static var pickUpAnnotation = MKPointAnnotation()
    static var dropOffAnnotation = MKPointAnnotation()
    var polyLine = MKPolyline()
    
    let uberRidesClient = RidesClient()
    
    let activityIndecatior:UIActivityIndicatorView = UIActivityIndicatorView()
    @IBAction func compareButton(_ sender: Any) {
        while !dataRetrived[0]{
        }
        while !dataRetrived[1]{
        }
        while !dataRetrived[2]{
        }
        while !dataRetrived[3]{
        }
        //        activityIndecatior.stopAnimating()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (CLLocationManager.locationServicesEnabled()){
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        mapView.delegate = self
        locationResultTableView.isHidden = true;
    }
}


extension ViewController: MKMapViewDelegate{
    //MARK: Called by polyLineRenderer
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: polyLine)
        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
        renderer.lineWidth = 5
        return renderer
    }
}

extension ViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(!ViewController.pickUpLocationSet){
            ViewController.pickUpLocationSet = true
            if let location = locations.last{
                let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
                self.mapView.setRegion(region, animated: true)
                
                getAddressFromLatLong(latLongCords: location)
                //                let priceViewController = PriceViewController();
                print("pickUpLocationSet")
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                ViewController.pickUpAnnotation = annotation
                completer.delegate = self
                completer.region = MKCoordinateRegion(center: center, latitudinalMeters: 10_000, longitudinalMeters: 10_000)
            }
        }
    }
}

extension ViewController: UISearchBarDelegate{
    func getAddressFromLatLong(latLongCords: CLLocation){
        CLGeocoder().reverseGeocodeLocation(latLongCords, completionHandler: {(placemarks, error) -> Void in
            if (error != nil)
            {
                print("reverse geodcode fail: \(error!.localizedDescription)")
            }
            let pm = placemarks! as [CLPlacemark]
            
            if pm.count > 0 {
                let pm = placemarks![0]
                //                    print(pm.country)
                //                    print(pm.locality)
                //                    print(pm.subLocality)
                //                    print(pm.thoroughfare)
                //                    print(pm.postalCode)
                //                    print(pm.subThoroughfare)
                var addressString : String = ""
                if pm.subThoroughfare != nil {
                    addressString = addressString + pm.subThoroughfare! + " "
                }
                if pm.thoroughfare != nil {
                    addressString = addressString + pm.thoroughfare! + " "
                }
                if pm.subLocality != nil {
                    addressString = addressString + pm.subLocality! + ", "
                }
                if pm.locality != nil {
                    addressString = addressString + pm.locality! + ""
                }
                print(addressString)
                self.pickUpLocationSearchBar.text = addressString
            }
        })
    }
    
    //MARK: called when user clicks on search bar
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        locationResultTableView.isHidden = false
        if(searchBar == pickUpLocationSearchBar){
            activeTextView = "top"
            completer.queryFragment = pickUpLocationSearchBar.text ?? " "
            completerDidUpdateResults(completer)
        }
        else{
            activeTextView = "bottom"
            completer.queryFragment = dropOffLocationSearchBar.text ?? " "
            completerDidUpdateResults(completer)
        }
        return true
    }
    //MARK: called when search button on keyboard is clicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        view.endEditing(true)
        locationResultTableView.isHidden = true;
    }
    //MARK: called when text changes (including clear)
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
        completer.queryFragment = searchText
        completerDidUpdateResults(completer)
    }
}



extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addresses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Default cell
        let cell = UITableViewCell()
        cell.textLabel!.text = addresses[indexPath.row]
        return cell;
    }
    
    //MARK: called when a location is clicked on tableView
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(addresses[indexPath.row])
        switch activeTextView{
        case "top":
            pickUpLocationSearchBar.text = addresses[indexPath.row]
            ViewController.pickUpLocation = addresses[indexPath.row].components(separatedBy: ",").first!
        default:
            dropOffLocationSearchBar.text = addresses[indexPath.row]
            ViewController.dropOffLocation = addresses[indexPath.row].components(separatedBy: ",").first!
        }
        locationResultTableView.isHidden = true
        view.endEditing(true)
        
        
        
        //MARK: Change address to lat long
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(addresses[indexPath.row]) { (placemarks, error) in
            guard
                let placemarks = placemarks,
                let location = placemarks.first?.location
                else {
                    // handle no location found
                    return
            }
            
            //handles location found
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            _ = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
            //            self.mapView.setRegion(region, animated: true)
            
            //MARK: Pickup/drop off annotations
            let annotation = MKPointAnnotation()
            annotation.coordinate = center
            switch self.activeTextView{
            case "top":
                self.mapView.removeAnnotation(ViewController.pickUpAnnotation)
                ViewController.pickUpAnnotation = annotation
                annotation.title = "Pickup Location"
            default:
                self.mapView.removeAnnotation(ViewController.dropOffAnnotation)
                ViewController.dropOffAnnotation = annotation
                annotation.title = "Drop off Location"
            }
            self.dataRetrived = [false,false,false,false]
            
            self.mapView.addAnnotation(annotation)
            
            //MARK: Handles direction line
            let directionRequest = MKDirections.Request()
            directionRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: ViewController.pickUpAnnotation.coordinate, addressDictionary: nil))
            directionRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: ViewController.dropOffAnnotation.coordinate, addressDictionary: nil))
            directionRequest.transportType = .automobile
            
            // MARK: Calculate the direction for AUTOMOBILE
            let directions = MKDirections(request: directionRequest)
            directions.calculate {
                (response, error) -> Void in
                guard let response = response else {
                    if let error = error {
                        print("Error: \(error)")
                    }
                    return
                }
                let route = response.routes[0]
                self.mapView.removeOverlay(self.polyLine)
                self.polyLine = route.polyline
                _ = MKPolylineRenderer(polyline: self.polyLine)
                self.mapView.addOverlay(self.polyLine, level: MKOverlayLevel.aboveRoads)
                let rect = route.polyline.boundingMapRect.insetBy(dx: 50, dy: 50)
                //                self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
                self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 40.0, left: 20.0, bottom: 20, right: 20.0), animated: true)
                ViewController.distance = round((route.distance * 0.00062137) * 10)/10 //convert meters to miles
                ViewController.travelTime = Int(round(route.expectedTravelTime / 60)) //convert seconds to minutes
            }
            
            //MARK: Calculate the directons for Public Trasportation
            directionRequest.transportType = .transit
            let publicTransportationETA = MKDirections(request: directionRequest)
            publicTransportationETA.calculateETA {
                (response, error) -> Void in
                guard let response = response else {
                    if let error = error {
                        print("Error: \(error)")
                    }
                    return
                }
                ViewController.publicTransportationTravelTime = Int(round(response.expectedTravelTime / 60)) //convert seconds to minutes
            }
            //MARK: Calculate the directons for Public Trasportation
            directionRequest.transportType = .walking
            let walkingETA = MKDirections(request: directionRequest)
            walkingETA.calculateETA {
                (response, error) -> Void in
                guard let response = response else {
                    if let error = error {
                        print("Error: \(error)")
                    }
                    return
                }
                ViewController.walkingTravelTime = Int(round(response.expectedTravelTime / 60)) //convert seconds to minutes
            }
           
            
            self.uberRidesClient.fetchTimeEstimates(pickupLocation: CLLocation(latitude: ViewController.pickUpAnnotation.coordinate.latitude, longitude: ViewController.pickUpAnnotation.coordinate.longitude), completion: { product, response in
                ViewController.uberTimes = product
                self.dataRetrived[0] = true
                
            })
            
            self.uberRidesClient.fetchPriceEstimates(pickupLocation: CLLocation(latitude: ViewController.pickUpAnnotation.coordinate.latitude, longitude: ViewController.pickUpAnnotation.coordinate.longitude), dropoffLocation: CLLocation(latitude: ViewController.dropOffAnnotation.coordinate.latitude, longitude: ViewController.dropOffAnnotation.coordinate.longitude), completion: { product, response in
                ViewController.uberPrices = product
                self.dataRetrived[1] = true
                
            })
            LyftAPI.costEstimates(from: ViewController.pickUpAnnotation.coordinate, to: ViewController.dropOffAnnotation.coordinate, rideKind: nil, completion: {
                response in
                if(response.value != nil){
                    ViewController.lyftPrices = response.value!
                    self.dataRetrived[2] = true
                }
                else{
                    ViewController.lyftPrices = []
                }
            })
            LyftAPI.ETAs(to: ViewController.pickUpAnnotation.coordinate, completion: {
                response in
                if(response.value != nil){
                    ViewController.lyftTimes = response.value!
                    self.dataRetrived[3] = true
                }
                else{
                    ViewController.lyftTimes = []
                }
            })
            
        }
    }
}

extension ViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        addresses = completer.results.map { result in
            result.title + ", " + result.subtitle
        }
        // Mark: Removes addresses that contain "Search Nearby"
            for i in (0..<addresses.count).reversed(){
                if addresses.count-1 > i {
                    if addresses[i].range(of:"Search Nearby") != nil {
                        print(addresses[i])
                        addresses.remove(at: i)
                    }
                }
            }
        
        // use addresses, e.g. update model and call `tableView.reloadData()
        locationResultTableView.reloadData();
    }
}

