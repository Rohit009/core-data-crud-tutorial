//
//  ViewController.swift
//  CoreDataDemo
//
//  Created by Rohit Patil on 11/07/20.
//  Copyright © 2020 Patil corp. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    let tableView = UITableView()
    
    var items: [Person]?
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.tableView)
        self.setupConstraints()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(self.didTapAddButton))
        
        self.fetchPeople()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            self.tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    private func fetchPeople() {
        do {
            let request = Person.fetchRequest() as NSFetchRequest<Person>

            // Filtering
            // let predicate = NSPredicate(format: "name CONTAINS 'Ted'")
            // request.predicate = predicate
            
            // Sorting
            let nameSortDescriptor =  NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [ nameSortDescriptor ]

            self.items = try self.context.fetch(request)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            assertionFailure("Core data fetch failed with: \(error)")
        }
    }
    
    func relationshipDemo() {
        // Create a family
        let family = Family(context: self.context)
        family.name = "Home town family"
        
        // Create a person
        let person = Person(context: self.context)
        person.name = "Maggie"
        
        // Add person to family
        family.addToPeople(person)
        
        // Save the context
        try! self.context.save()
        
        // When fetched Person object from core data. Its relative family object can be fetched from person.family.
    }

    // MARK: Tap handlers

    @objc func didTapAddButton() {
        print("Did tap add button")
        
        let alertController = UIAlertController(
            title: "Add Person",
            message: "What is the name of person ?",
            preferredStyle: .alert)
        alertController.addTextField()
        alertController.addAction(.init(title: "Ok", style: .default, handler: { [weak self] (alertAction) in
            let textField = alertController.textFields?.first
            self?.enteredText(textField?.text)
        }))
        self.present(alertController, animated: true)
    }
    
    private func enteredText(_ text: String?) {
        guard let enteredText = text, enteredText.count > 0 else {
            return
        }
        
        print("User has entered: \(enteredText)")
        
        let newPerson = Person(context: self.context)
        newPerson.name = enteredText
        newPerson.age = 20
        newPerson.gender = "Male"
        
        self.saveInCoreData()
        
        self.fetchPeople()
    }
    
    private func saveInCoreData() {
        do {
            try self.context.save()
        } catch {
            assertionFailure("Core data save failed with: \(error)")
        }
    }

}

// MARK: - UITableViewDelegate

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alertController = UIAlertController(
            title: "Update Person",
            message: "Please update the name of person in following field ?",
            preferredStyle: .alert)
        let personToUpdate = self.items?[indexPath.row]

        alertController.addTextField { (textField) in
            if let name = personToUpdate?.name {
                textField.text = name
            }
        }
        alertController.addAction(.init(title: "Ok", style: .default, handler: { [weak self] (alertAction) in
            let textField = alertController.textFields?.first
            
            personToUpdate?.name = textField?.text
            
            self?.saveInCoreData()
            
            self?.fetchPeople()
        }))
        self.present(alertController, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self)) ?? UITableViewCell()
        
        let person = self.items?[indexPath.row]
        cell.textLabel?.text = person?.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { (action, view, completionHandler) in
            if let personToRemove = self.items?[indexPath.row] {
                
                self.context.delete(personToRemove)
                
                self.saveInCoreData()
            
                print("Deleted: \(personToRemove.name ?? "")")
                self.fetchPeople()
            }
        }
        
        return UISwipeActionsConfiguration(actions: [action])
    }
}
