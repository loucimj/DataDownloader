//
//  DataDownloader.swift
//  DataDownloaderTest
//
//  Created by Javier Loucim on 22/07/2018.
//  Copyright © 2018 Qeeptouch. All rights reserved.
//

import Foundation
import Alamofire

///Notes to implement DataDownloader
/// Add the following code to your AppDelegate
/*
 
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        DataDownloaderData.shared.backgroundCompletionHandler = completionHandler
    }
*/

struct DataDownloadTask {
    enum DataDownloadTaskMethod:String {
        case get = "GET"
        case post = "POST"
    }
    var method:DataDownloadTaskMethod = .get
    var url:String
    var filename:String
    var headers:[String:String]?
    var path:String
    var fileAbsoluteURL:String {
        get {
            return path+"/"+filename
        }
    }
    var notificationMessageWhenDownloaded:String?
    
    init(url: String, filename:String) {
        self.path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        self.filename = filename
        self.url = url
    }
}

extension DataDownloadTask: Equatable {
    
    static func ==(lhs: DataDownloadTask, rhs: DataDownloadTask) -> Bool {
        guard lhs.filename == rhs.filename else {
            return false
        }
        return true
    }

}

class DataDownloaderData: NSObject, NotificationSender {
    static var shared = DataDownloaderData()
    lazy var dataToDownload:Array<DataDownloadTask> = Array<DataDownloadTask>()
    
    lazy var backgroundHandler: Alamofire.SessionManager = {
        let identifier = Bundle.main.bundleIdentifier! + ".dataDownloaderTasks"
        var configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.isDiscretionary = true
        configuration.sessionSendsLaunchEvents = true
        configuration.sharedContainerIdentifier = identifier
        let handler = Alamofire.SessionManager(configuration: configuration)
        return handler
    }()
    var backgroundCompletionHandler: (() -> Void)? {
        get {
            return backgroundHandler.backgroundCompletionHandler
        }
        set {
            backgroundHandler.backgroundCompletionHandler = newValue
        }
    }
    
    var dataDownloaderNotificationTitle:String = "Data Downloader"
    var dataDownloaderNotificationShouldSendNotifications:Bool = true {
        didSet {
            if dataDownloaderNotificationShouldSendNotifications {
                self.requestPushNotificationAuthorization()
            }
        }
    }
}
extension DataDownloaderData: URLSessionDelegate {
    
}


protocol DataDownloader: NotificationSender {
    func dataDonwloadHadProblems(dataDownloadTask:DataDownloadTask, errorMessage:String)
    func dataWasDownloaded(dataDownloadTask:DataDownloadTask)
    func progressForDataDownload(dataDownloadTask:DataDownloadTask, progress:Double)
}

extension DataDownloader {
    func dataWasDownloaded(dataDownloadTask:DataDownloadTask) {}
    

    func configureDataDownloaderNotifications(enable:Bool, title:String = "Data Downloader") {
        DataDownloaderData.shared.dataDownloaderNotificationTitle = title
        DataDownloaderData.shared.dataDownloaderNotificationShouldSendNotifications = enable
    }
    
    func addDataToDownloadList(dataDownloadTask:DataDownloadTask) {
        DataDownloaderData.shared.dataToDownload.append(dataDownloadTask)
        startBackgroundDownload(for: dataDownloadTask)
    }
    
    func removeDataDownloadFromList(dataDownloadTask:DataDownloadTask) {
        print ("removing \(dataDownloadTask.filename)")
        DataDownloaderData.shared.dataToDownload = DataDownloaderData.shared.dataToDownload.filter({$0 != dataDownloadTask})
    }
    
    fileprivate func startBackgroundDownload(for dataDownloadTask:DataDownloadTask) {
        DataDownloaderData.shared.backgroundHandler.startRequestsImmediately = true
        guard let url = URL(string: dataDownloadTask.url) else {
            removeDataDownloadFromList(dataDownloadTask: dataDownloadTask)
            return
        }
        let method:HTTPMethod = dataDownloadTask.method == .get ? .get : .post
        do {
            let urlRequest = try URLRequest(url: url, method: method, headers: dataDownloadTask.headers)
            print ("starting \(url)")
            
            
            DataDownloaderData.shared.backgroundHandler.request(urlRequest)
                .responseData { (response) in
                    if response.response?.statusCode == 200 {
                        print ("completion \(dataDownloadTask.url) - \(dataDownloadTask.fileAbsoluteURL)")
                        FileManager.default.createFile(atPath: dataDownloadTask.fileAbsoluteURL, contents: response.data, attributes: nil)
                        self.removeDataDownloadFromList(dataDownloadTask: dataDownloadTask)
                        if DataDownloaderData.shared.dataDownloaderNotificationShouldSendNotifications {
                            self.sendNotification(title: DataDownloaderData.shared.dataDownloaderNotificationTitle, subtitle: "", body: dataDownloadTask.notificationMessageWhenDownloaded ?? (dataDownloadTask.filename + " was downloaded"))
                        }
                        self.dispatchEvent {
                            self.dataWasDownloaded(dataDownloadTask: dataDownloadTask)
                        }
                    } else {
                        if let data:Data = response.result.value {
                            self.dispatchEvent {
                                self.dataDonwloadHadProblems(dataDownloadTask: dataDownloadTask, errorMessage: String(data: data, encoding: .utf8)!)
                            }
                        } else {
                            self.dispatchEvent {
                                print("\(response)")
                                self.dataDonwloadHadProblems(dataDownloadTask: dataDownloadTask, errorMessage: "There was an error downloading the file")
                            }
                        }
                    }
                }
                .downloadProgress { progress in
                    self.dispatchEvent {
                        self.progressForDataDownload(dataDownloadTask: dataDownloadTask, progress: Double(progress.fractionCompleted))
                    }
                }
        
        } catch {
            removeDataDownloadFromList(dataDownloadTask: dataDownloadTask)
            return
        }
        

    }
    
    fileprivate func dispatchEvent(block:@escaping ()->()) {
        DispatchQueue.main.async {
            block()
        }
    }
    
    func getPendingDownloadsCount() -> Int {
        return DataDownloaderData.shared.dataToDownload.count
    }
}

