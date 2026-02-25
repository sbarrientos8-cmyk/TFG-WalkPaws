//
//  NewsController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 23/2/26.
//

import UIKit

class NewsController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableNews: UITableView!
    @IBOutlet weak var bottomBar: BottomBar!
    
    
    private var news: [NewsModel] = []

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        bottomBar.selectSection(.news)


        loadNews()
        hideKeyboardWhenTappedAround()
        setupTable()
    }
    
    private func setupTable() {
        tableNews.dataSource = self
        tableNews.delegate = self

        let nib = UINib(nibName: "NewCell", bundle: nil)
        tableNews.register(nib, forCellReuseIdentifier: "NewCell")

        tableNews.rowHeight = UITableView.automaticDimension
        tableNews.estimatedRowHeight = 140

        tableNews.backgroundColor = .clear
    }
    
    private func loadNews() {
        fetchNews { [weak self] models in
            DispatchQueue.main.async {
                self?.news = models
                self?.tableNews.reloadData()
            }
        }
    }

        
    // MARK: - TABLE VIEW
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return news.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewCell", for: indexPath) as? NewCell else {
            return UITableViewCell()
        }

        let item = news[indexPath.row]
        cell.selectionStyle = .none
        cell.config(with: item)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = news[indexPath.row]

        let vc = NewsDetailController(nibName: "NewsDetailController", bundle: nil)
        vc.news = item
        navigationController?.pushViewController(vc, animated: true)
    }

}
