//
//  DetailsViewController.swift
//  FairRide
//
//  Created by Stephen Fung on 8/21/18.
//  Copyright © 2018 Stephen Fung. All rights reserved.
//

import UIKit
import LyftSDK
import CoreLocation
import UberRides

class DetailsViewController: UIViewController{
    
    @IBOutlet weak var closestRideLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var surchageLabel: UILabel!
    @IBOutlet weak var banner: UIImageView!
    
//    @IBOutlet weak var btnLyft: LyftButton!
     let btnLyft = LyftButton()
    let btnUber = RideRequestButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        banner.image = UIImage(named: "FairRideBanner")
        
        //TODO: Fix label for closest ride label, always displays "to John F Kenedy Airport
        closestRideLabel.text = "\(PriceViewController.time) minutes to closest ride"
        destinationLabel.text = "to \(ViewController.dropOffLocation)"
        destinationLabel.sizeToFit()
        costLabel.text = "$\(PriceViewController.cost[0]) - \(PriceViewController.cost[1]) estimated fare"
        surchageLabel.text = "\(PriceViewController.surcharge) times surcharge"
        
        //        let btnLyft = LyftButton()
    
        if(!PriceViewController.uberLyftArray[PriceViewController.buttonIndex].isUber){
            self.view.willRemoveSubview(btnUber)
            
            let pickup = ViewController.pickUpAnnotation.coordinate
            let destination = ViewController.dropOffAnnotation.coordinate
            btnLyft.configure(rideKind: PriceViewController.uberLyftArray[PriceViewController.buttonIndex].LyftRideKind, pickup: pickup, destination: destination)
            self.view.addSubview(btnLyft)
            
        }
        else{
            self.view.willRemoveSubview(btnLyft)
            
            // set a dropoffLocation
            let pickUpLocation = CLLocation(latitude: ViewController.pickUpAnnotation.coordinate.latitude, longitude: ViewController.pickUpAnnotation.coordinate.longitude)
            let dropoffLocation = CLLocation(latitude: ViewController.dropOffAnnotation.coordinate.latitude, longitude: ViewController.dropOffAnnotation.coordinate.longitude)
            let builder = RideParametersBuilder()
            builder.pickupLocation = pickUpLocation
            builder.pickupNickname = ViewController.pickUpLocation
            builder.dropoffLocation = dropoffLocation
            builder.dropoffNickname = ViewController.dropOffLocation
            builder.productID = PriceViewController.uberLyftArray[PriceViewController.buttonIndex].UberRideKind
            btnUber.rideParameters = builder.build()
            self.btnUber.loadRideInformation()
            
            //put the button in the view
            view.addSubview(btnUber)
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        btnLyft.frame = CGRect(x: self.view.center.x - 130, y: self.view.frame.size.height - 50 - view.safeAreaInsets.bottom, width: 260, height: 50)
        btnUber.frame = CGRect(x: self.view.center.x - 130, y: self.view.frame.size.height - 50 - view.safeAreaInsets.bottom, width: 260, height: 50)
    }
    
}
