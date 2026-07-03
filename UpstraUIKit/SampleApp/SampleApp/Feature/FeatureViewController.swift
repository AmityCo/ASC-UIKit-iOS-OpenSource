//
//  FeatureViewController.swift
//  SampleApp
//
//  Created by Sarawoot Khunsri on 15/7/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import SwiftUI
import AmityUIKit4

class FeatureViewController: UIViewController {

    enum FeatureList: CaseIterable {
        case data
        case chatV4
        case socialUIKit
        case userProfile
        case syncNetworkConfig
        var text: String {
            switch self {
            case .data:
                return "Data"
            case .chatV4:
                return "Chat v4"
            case .socialUIKit:
                return "Social UIKit 4"
            case .userProfile:
                return "User Profile"
            case .syncNetworkConfig:
                return "Sync Network Config"
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
        case .data:
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DataListViewController")
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .chatV4:
            let vc = ChatV4FeatureViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .socialUIKit:
            let pageView = AmitySocialHomePage(showBackButton: true)
            let hostingController = AmitySwiftUIHostingController(rootView: pageView)
            hostingController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(hostingController, animated: true)
        case .userProfile:
            let profilePage = AmityUserProfilePage(userId: AmityUIKit4Manager.client.currentUserId ?? "")
            let host = AmitySwiftUIHostingController(rootView: profilePage)
            let profilenavigationController = AmitySwiftUIHostingNavigationController(rootView: profilePage)
            profilenavigationController.modalPresentationStyle = .fullScreen
            self.navigationController?.pushViewController(host)
        case .syncNetworkConfig:
            Task { @MainActor in
                
                do {
                    try await AmityUIKit4Manager.syncNetworkConfig()
                    let successAlert = UIAlertController(title: "Success", message: "Network configuration sync successfully", preferredStyle: .alert)
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(successAlert, animated: true)
                } catch {
                    let errorAlert = UIAlertController(title: "Error", message: "Failed to sync network config: \(error.localizedDescription)", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(errorAlert, animated: true)
                }
            }
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

// "Chat v4" group: hosts the v4 chat entries — LiveChat and ChatHomePage.
final class ChatV4FeatureViewController: UITableViewController {

    enum FeatureList: CaseIterable {
        case liveChat
        case chatHomePage

        var text: String {
            switch self {
            case .liveChat:
                return "Live Chat"
            case .chatHomePage:
                return "Chat Home Page"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chat v4"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CellID")
        tableView.tableFooterView = UIView()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FeatureList.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellID", for: indexPath)
        cell.textLabel?.text = FeatureList.allCases[indexPath.row].text
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch FeatureList.allCases[indexPath.row] {
        case .liveChat:
            let hostingController = AmitySwiftUIHostingController(rootView: LiveChatListView())
            navigationController?.pushViewController(hostingController, animated: true)
        case .chatHomePage:
            let page = AmityChatHomePage()
            let hostingController = AmitySwiftUIHostingController(rootView: page)
            hostingController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(hostingController, animated: true)
        }
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
