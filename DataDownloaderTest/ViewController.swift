//
//  ViewController.swift
//  DataDownloaderTest
//
//  Created by Javier Loucim on 22/07/2018.
//  Copyright © 2018 Qeeptouch. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        addDataToDownloadList(dataDownloadTask: DataDownloadTask(url: "http://ipv4.download.thinkbroadband.com/10MB.zip", filename: "10Megabytesfile.zip"))
//        addDataToDownloadList(dataDownloadTask: DataDownloadTask(url: "http://ipv4.download.thinkbroadband.com/50MB.zip", filename: "another50MB.zip"))
//        addDataToDownloadList(dataDownloadTask: DataDownloadTask(url: "http://ipv4.download.thinkbroadband.com/20MB.zip", filename: "yetAnother20MB.zip"))
        let token = "8310638fvk7tiqvtmqpv3jksrk"
        var task = DataDownloadTask(url: "http://api.qa.sales-simulator.calculistik.com/target", filename: "salesTarget.json")
        task.headers = ["authentication-token": token]
        task.notificationMessageWhenDownloaded = "Sales plan was downloaded"
        addDataToDownloadList(dataDownloadTask: task)

        var task2 = DataDownloadTask(url: "http://ipv4.download.thinkbroadband.com/20MB.zip", filename: "10mb.zip")
        task2.notificationMessageWhenDownloaded = "Dummy 10 Mb file downloaded"
        addDataToDownloadList(dataDownloadTask: task2)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: DataDownloader {
    func progressForDataDownload(dataDownloadTask: DataDownloadTask, progress: Double) {
        print("\(dataDownloadTask.filename) \(progress)")
    }
    
    
    func dataDonwloadHadProblems(dataDownloadTask: DataDownloadTask, errorMessage: String) {
        print("\(dataDownloadTask.filename) \(errorMessage)" )
    }
    
    func dataWasDownloaded(dataDownloadTask: DataDownloadTask) {
        print((1-(Double(getPendingDownloadsCount())/3.0))*100)
        
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: dataDownloadTask.fileAbsoluteURL)
            if let fileSize = fileAttributes[FileAttributeKey.size]  {
                print ((fileSize as! NSNumber).uint64Value)
            } else {
                print("Failed to get a size attribute from path: \(dataDownloadTask.fileAbsoluteURL)")
            }
        } catch {
            print("Failed to get file attributes for local path: \(dataDownloadTask.fileAbsoluteURL) with error: \(error)")
        }
    }
}

