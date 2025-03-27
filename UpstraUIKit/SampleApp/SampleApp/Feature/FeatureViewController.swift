//
//  FeatureViewController.swift
//  SampleApp
//
//  Created by Sarawoot Khunsri on 15/7/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import AmityUIKit
import UIKit
import SwiftUI
import AmityUIKit4

class FeatureViewController: UIViewController {
    
    enum FeatureList: CaseIterable {
        case chatFeature
        case community
        case data
        case chatUIKit
        case socialUIKit
        case socialUIKitV4Comaptible
        case userProfile
        
        var text: String {
            switch self {
            case .chatFeature:
                return "Chat"
            case .community:
                return "Community"
            case .data:
                return "Data"
            case .chatUIKit:
                return "Chat UIKit 4"
            case .socialUIKit:
                return "Social UIKit 4"
            case .socialUIKitV4Comaptible:
                return "Social UIKit 4 Compatible"
            case .userProfile:
                return "User Profile"
            }
        }
    }
    
    @IBOutlet private var tableView: UITableView!
    private var logoutButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Feature"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CellID")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        
        logoutButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutTap))
        navigationItem.rightBarButtonItem = logoutButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @objc private func logoutTap() {
        AppManager.shared.unregister()
    }
    
}

extension FeatureViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch FeatureList.allCases[indexPath.row] {
        case .chatFeature:
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatFeatureViewController")
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .community:
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CommunityFeatureViewController")
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .data:
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DataListViewController")
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .chatUIKit:
            let view = LiveChatListView()
            let hostingController = AmitySwiftUIHostingController(rootView: view)
            
            //            if #available(iOS 15.0, *) {
            //                if let sheet = hostingController.sheetPresentationController {
            //                    sheet.detents = [.large()]
            //                    sheet.prefersGrabberVisible = true
            //                }
            //            }
            //            navigationController?.present(hostingController, animated: true)
            navigationController?.pushViewController(hostingController, animated: true)
        case .socialUIKit:
            let pageView = AmitySocialHomePage(showBackButton: true)
            let hostingController = AmitySwiftUIHostingController(rootView: pageView)
            hostingController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(hostingController, animated: true)
        case .socialUIKitV4Comaptible:
            let homepage = AmitySocialV4Compatible.make()
            let navigationController = UINavigationController(rootViewController: homepage)
            navigationController.modalPresentationStyle = .fullScreen
            present(navigationController, animated: true, completion: nil)
        case .userProfile:
            let profilePage = AmityUserProfilePage(userId: AmityUIKit4Manager.client.currentUserId ?? "")
//            let navigationController = AmitySwiftUIHostingNavigationController(rootView: profilePage)
//            navigationController.modalPresentationStyle = .fullScreen
//            present(navigationController, animated: true, completion: nil)
            self.navigationController?.pushViewController(AmitySwiftUIHostingController(rootView: profilePage), animated: true)
        }

    }
}

extension FeatureViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FeatureList.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellID", for: indexPath)
        cell.textLabel?.text = FeatureList.allCases[indexPath.row].text
        return cell
    }
}

// Sample View which uses live chat page inside a sheet.
struct ChatV4SheetView: View {
    var body: some View {
        ZStack {
            Color(hex: "191919")
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(hex: "191919"))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                
                AmityLiveChatPage(channelId: "")
            }
        }
        .colorScheme(.dark)
        .preferredColorScheme(.dark)
    }
}

extension Color {
    
    init(hex: String) {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            self.init(.gray)
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        self.init(.sRGB, red: Double(((rgbValue & 0xFF0000) >> 16)) / 255.0, green: Double((rgbValue & 0x00FF00) >> 8) / 255.0, blue: Double(rgbValue & 0x0000FF) / 255.0, opacity: 1.0)
    }
}
