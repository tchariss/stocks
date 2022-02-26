//
//  InfoViewController.swift
//  Stocks
//
//  Created by Виктория Шеховцова on 11.02.2022.
//

import UIKit

class InfoViewController: UIViewController {

    private var name: String = ""
    private let infoCompany = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        requestQuote(for: name)
    }
    
    private func requestQuote(for symbol: String) {
        guard let myUrl = Bundle.main.path(forResource: "\(name)", ofType: "txt") else { fatalError("File not found") }
        let url = URL(fileURLWithPath: myUrl)
        
        let request = URLRequest(url: url)
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("❗️ Error : \(error)")
                return
            }
            else if let data: Data = data     {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data)
                    
                    guard
                        let json = jsonObject as? [String: String],
                        let info = json["info"]
                    else {
                        print("❗️ Invalid JSON format ❗️")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.setupText(text: info)
                    }
                } catch {
                    print("❗️ JSON pasing error: " + error.localizedDescription)
                }
            }
        }
        dataTask.resume()
    }

    private func setupText(text: String) {
        infoCompany.text = text

        infoCompany.textColor = .black
        
        infoCompany.numberOfLines = 0
        infoCompany.lineBreakMode = .byWordWrapping

        infoCompany.font = UIFont.systemFont(ofSize: 14)
        
        view.addSubview(infoCompany)
        
        infoCompany.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            infoCompany.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            infoCompany.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoCompany.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
}

extension InfoViewController {
    func configure(symbolCompany: String) {
        name = symbolCompany
    }
}
