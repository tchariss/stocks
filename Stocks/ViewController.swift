//
//  ViewController.swift
//  Stocks
//
//  Created by Виктория Шеховцова on 10.02.2022.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var companyNameLabel: UILabel!
    
    @IBOutlet weak var companySymbolLabel: UILabel! = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingMiddle
        
        return label
    }()
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var labelArrow: UILabel!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var companyLogo: UIImageView!
    
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
// MARK: - private properties
    let customImage = UIImage(systemName: "arrow.up")
    
    private let token: String = "pk_ad8642e599b24753b6cb7c929da7e128"

    private let myColor = UIColor(red: 0.89, green: 0.20, blue: 0.76, alpha: 1.0)
    
    // Dictionary company
    private let companies: [String: String] = ["Apple" : "AAPL",
                                               "Microsoft" : "MSFT",
                                               "Google" : "GOOG",
                                               "Amazon" : "AMZN",
                                               "Facebook" : "FB"]

// MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Stocks"
        self.view.backgroundColor = .white
        navigationController?.navigationBar.tintColor = myColor
        
        self.companyPickerView.dataSource = self
        self.companyPickerView.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true

        self.requestQuoteUpdate()
        addNavigationBar()
    }

    // MARK: - Private methods

    private func requestQuote(for symbol: String) {
        let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?&token=\(token)")!
        let urlImage = URL(string: "https://storage.googleapis.com/iex/api/logos/\(symbol).png")!
        
        let request = URLRequest(url: url)
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { (data, response, error) in

            guard error == nil,
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let data = data
            else {
                DispatchQueue.main.async {
                    self.presentAlertController()
                }
                print("❗️ Network error ❗️")
                return
            }
            
            DispatchQueue.main.async {
                if let dataImage = try? Data(contentsOf: urlImage) {
                    self.companyLogo.image = UIImage(data: dataImage)
                }
            }
            
            self.parseQuote(data: data)
        }
        dataTask.resume()
    }
    
    private func presentAlertController() {
        let alert = UIAlertController(title: "Error",
                                      message: "Internet connection error",
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)

        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    private func parseQuote(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double
            else {
                print("❗️ Invalid JSON format ❗️")
                return
            }
            DispatchQueue.main.async {
                self.displayStockInfo(companyName: companyName,
                                      symbol: companySymbol,
                                      price: price,
                                      priceChange: priceChange)
            }
        } catch {
            print("❗️ JSON pasing error: " + error.localizedDescription)
        }
    }
    
    private func requestQuoteUpdate() {
        self.activityIndicator.startAnimating()
        self.companyNameLabel.text = "—"
        self.companySymbolLabel.text = "—"
        self.priceLabel.text = "—"
        self.priceChangeLabel.text = "—"

        let selectedRow = self.companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(self.companies.values)[selectedRow] // Символ выбранной компании

        self.requestQuote(for: selectedSymbol)
    }
    
    private func displayStockInfo(companyName: String, symbol: String, price: Double, priceChange: Double) {
        self.activityIndicator.stopAnimating()
        self.companyNameLabel.text = companyName
        self.companySymbolLabel.text = symbol
        
        self.companyLogo.backgroundColor = .white
        self.companyLogo.layer.cornerRadius = companyLogo.frame.size.width / 2
        self.companyLogo.layer.borderWidth = 0.6
        self.companyLogo.layer.borderColor = UIColor.black.cgColor
        
        rightBarStarButton.backgroundImage(for: .selected)
        
        self.priceLabel.text = "\(price)"
    
        self.priceChangeLabel.text = "\(priceChange)"
        if priceChange > 0.0 {
            self.priceChangeLabel.textColor = UIColor.systemGreen // Выросла цена
            self.labelArrow.text = "↑"
            self.labelArrow.textColor = UIColor.systemGreen
        }
        else {
            self.priceChangeLabel.textColor = .red // Упала цена
            self.labelArrow.text = "↓"
            self.labelArrow.textColor = UIColor.red
        }
    }
   
    // MARK: - private navigation properties
    
    private let rightBarStarButton = UIButton()
    private let star = UIImage(systemName: "star")
    private let starFill = UIImage(systemName: "star.fill")
    private var isPressed = false
    private var currentCompany: String = ""
    private var arrayIsPressed: Dictionary<String, Bool> = [:]
    
    // MARK: - NavigationBar
    
    func addNavigationBar() {

        rightBarStarButton.setImage(star, for: .normal)
        rightBarStarButton.addTarget(self, action: #selector(buttonPress(_:)), for: .touchUpInside)
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "info.circle"),
                             style: .done,
                             target: self,
                             action: #selector(switchNewController(_:))),
            
            UIBarButtonItem(customView: rightBarStarButton) ]
        
        Array(self.companies.keys).map {
            arrayIsPressed[$0] = false
        }
    }
    
    private func checkPicker(company: String) {
        
        guard let isPressed = arrayIsPressed[company] else { return }
              
        if !isPressed {
            rightBarStarButton.setImage(star, for: .normal)
            arrayIsPressed.updateValue(false, forKey: company)
        }
        else {
            rightBarStarButton.setImage(starFill, for: .normal)
        }
    }
    
    private func checkStar(company: String) {
        
        guard let isPressed = arrayIsPressed[company] else { return }

        if isPressed {
            rightBarStarButton.setImage(star, for: .normal)
            arrayIsPressed.updateValue(false, forKey: company)
        }
        else {
            rightBarStarButton.setImage(starFill, for: .normal)
            arrayIsPressed.updateValue(true, forKey: company)
        }
    }
    
    @objc private func buttonPress(_ sender: UIBarButtonItem) {
        rightBarStarButton.backgroundImage(for: .selected)
        checkStar(company: currentCompany)
    }
    
    @objc private func switchNewController(_ sender: UIBarButtonItem) {
        let newController = InfoViewController()
        newController.title = companyNameLabel.text
        
        newController.configure(symbolCompany: currentCompany)

        self.navigationController?.pushViewController(newController, animated: true)
    }
}

// MARK: - UIPickerViewDataSource

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.companies.keys.count
    }
}

// MARK: - UIPickerViewDelegate

extension ViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        currentCompany = Array(self.companies.keys)[row]
        return currentCompany
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.activityIndicator.startAnimating()

        let selectedSymbol = Array(self.companies.values)[row]

        currentCompany = Array(self.companies.keys)[row]
        checkPicker(company: currentCompany)
        
        self.requestQuote(for: selectedSymbol)
    }
}
