//
//  PriceViewController.swift
//  FairRide
//
//  Created by Stephen Fung on 8/8/18.
//  Copyright © 2018 Stephen Fung. All rights reserved.
//

import UIKit
import UberRides
import LyftSDK
import UberCore

class PriceViewController: UIViewController {
    
    @IBOutlet weak var distanecTimeLabel: UILabel!
    static var buttonIndex = 0
    static var uberLyftArray = [uberLyftItem]()
    
    struct uberLyftItem {
        var isUber = false
        var rideName = ""
        var minCost = 0
        var maxCost = 0
        var closestRide = 0
        var surcharge = 0.0
        var LyftRideKind: LyftSDK.RideKind = LyftSDK.RideKind.Standard;
        var UberRideKind: String = ""
    }
    
    var closestRideArray = [closestRide]()
    struct closestRide{
        var rideType = ""
        var minutes = 0
    }
    static var cost = [0,0]
    static var time = 0
    static var surcharge = 0.0
    static var rideName = ""
    
    @IBOutlet var ridesButton: [UIButton]!
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for button in ridesButton{
            button.setTitle("", for: .normal)
            button.setImage(nil, for: .normal)
        }
        PriceViewController.uberLyftArray.removeAll()
        count = 0;
        distanecTimeLabel.text = "Distance: " + String(ViewController.distance) + " miles" + "\n Expected travel time: " + String(ViewController.travelTime) + " minutes"
        
        //Mark: Add Uber's to array
        for uber in ViewController.uberTimes{
            closestRideArray.append(closestRide(rideType: uber.name!, minutes: uber.estimate! / 60))
        }
        for uber in ViewController.uberPrices{
            var nearest = 0
            for ride in closestRideArray{
                if ride.rideType == uber.name{
                    nearest = ride.minutes
                    break
                }
            }
            if(uber.lowEstimate != nil){
                PriceViewController.uberLyftArray.append(uberLyftItem(isUber: true, rideName: uber.name!, minCost: uber.lowEstimate!, maxCost: uber.highEstimate!, closestRide: nearest, surcharge: uber.surgeMultiplier ?? 0.0, LyftRideKind: LyftSDK.RideKind.Standard, UberRideKind: uber.productID!))
            }
        }
        
        //Mark: Add Lyft's to array
        for lyft in ViewController.lyftTimes{
            closestRideArray.append(closestRide(rideType: lyft.displayName, minutes: lyft.seconds / 60))
        }
        for index in ViewController.lyftPrices.indices{
            let lyft = ViewController.lyftPrices[index]
            var nearest = 0
            for ride in closestRideArray{
                if ride.rideType == lyft.displayName{
                    nearest = ride.minutes
                    break
                }
            }
            PriceViewController.uberLyftArray.append(uberLyftItem(isUber: false, rideName: lyft.displayName, minCost: Int((lyft.estimate?.minEstimate.amount.description)!)!, maxCost: Int((lyft.estimate?.maxEstimate.amount.description)!)!, closestRide: nearest, surcharge: Double(lyft.primeTimePercentageText) ?? 0, LyftRideKind: lyft.rideKind, UberRideKind: "0"))
        }
        
//        PriceViewController.uberLyftArray.sort { (lhs, rhs) -> Bool in
//            lhs.minCost < rhs.minCost
//        }
        
        //Add all items to main array
        for item in PriceViewController.uberLyftArray{
            ridesButton[count].setTitle("$\(item.minCost) - \(item.maxCost) \n\n\n\n\n \(item.closestRide) min", for: .normal)
            
            ridesButton[count].setImage(UIImage(named: item.rideName), for: .normal)
            ridesButton[count].titleEdgeInsets = UIEdgeInsets(top: 7, left: -124.3, bottom: 0, right: 0)
            ridesButton[count].contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.center
            ridesButton[count].contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
            ridesButton[count].imageEdgeInsets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
            count+=1
        }
    }
    
    @IBAction func buttonClicked(_ sender: UIButton) {
        PriceViewController.buttonIndex = 0
        for i in ridesButton.indices{
            if ridesButton[i] == sender{
                PriceViewController.buttonIndex = i
                break
            }
        }
        
        if(PriceViewController.uberLyftArray.count > PriceViewController.buttonIndex){
            PriceViewController.time = PriceViewController.uberLyftArray[PriceViewController.buttonIndex].closestRide
            PriceViewController.cost = [PriceViewController.uberLyftArray[PriceViewController.buttonIndex].minCost, PriceViewController.uberLyftArray[PriceViewController.buttonIndex].maxCost]
            PriceViewController.surcharge = PriceViewController.uberLyftArray[PriceViewController.buttonIndex].surcharge
            PriceViewController.rideName = PriceViewController.uberLyftArray[PriceViewController.buttonIndex].rideName
        }
    }
    
}
