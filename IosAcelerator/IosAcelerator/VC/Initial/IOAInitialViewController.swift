//
//  ViewController.swift
//  IosAcelerator
//
//  Created by Pedro Eduardo Waquim on 25/01/2019.
//  Copyright © 2019 Pedro Eduardo Waquim. All rights reserved.
//

import UIKit
import MLNetworking
import ProgressHUD

struct Sort {
    static let track = 0
    static let releaseDate = 1
}

class IOAInitialViewController: UIViewController {
    
    @IBOutlet weak var orderChooser: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var orderRevertSwitch: UISwitch!
    
    private var selectedSortAlg: Int = 0
    private let baseUrl = "https://itunes.apple.com/search?term="
    
    override func viewDidLoad() {
        super.viewDidLoad()
        orderRevertSwitch.setOn(false, animated: false)
    }
    
    
    func parserJson(data: Data?) -> IOAModel? {
        // Chequeo los datos
        guard let data = data else { return nil }
        
        // Decodifico y Chequeo que se haga correctamente
        guard let model = try? JSONDecoder().decode(IOAModel.self, from: data) else {
            print("Error: Couldn't decode data into IOAModel")
            return nil
        }
        
        return model
    }
    
    func sortingSongs(model: IOAModel) -> [Track] {
        // Obtener el algoritmo de ordenamiento deseado
        let sortedAlg: Int = self.selectedSortAlg
        
        // Obtener los datos
        var results: [Track] = model.results
        
        // Ordenar
        switch (sortedAlg) {
        case Sort.track:
            results = self.ordenarPorTrack(array: results)
            break;
        case Sort.releaseDate:
            results = self.ordenarPorFecha(array: results)
            break;
        default:
            break;
        }
        
        // Revertir si hace falta
        let switchIsOn = self.orderRevertSwitch.isOn
        if switchIsOn {
            results = self.ordenarInvertido(array: results)
        }
        
        return results
    }
    
    func createURL() -> String? {
        // Chequear el TextField
        guard let text = self.searchTextField.text else{
            return nil
        }
        
        // Formatear lo introducido
        var url = baseUrl + String.formattedWithoutRegExp(string: text)
        url = String.formattedURLParams(params: url)
        return url
    }
    
    @IBAction func onClickSelection(_ sender: UIButton) {
        
        guard let url = createURL() else {
            return
        }
        
        // Lanzar Animacion
        ProgressHUD.show();
        
        // Evitar Retaining circles
        weak var weakSelf = self
        
        // Success Completion
        let onSuccess: (Data?, URLResponse?) -> Void = {
            (data, response) in
            
            // ------------  Parseo datos ------------//
            guard let model = weakSelf?.parserJson(data: data) else {
                // Actualizo el estado en la UI
                ProgressHUD.dismiss()
                return
            }
            
            
            // ------------  Realizo ordenamiento ------------//
            guard let results = weakSelf?.sortingSongs(model: model) else{
                // Actualizo el estado en la UI
                ProgressHUD.dismiss()
                return
            }
       
            // ------------ Actualizo la UI ------------//
            
            // Stop Indicator
            ProgressHUD.dismiss()
            // Create Table Controller
            let tableViewController = IOATableViewController(model: results)
            weakSelf?.navigationController?.pushViewController(tableViewController, animated: true)
        }
        
        // Error completion
        let onError: (Error?) -> Void = {
            error in
            // Stop Indicator
            ProgressHUD.dismiss()
            // Chequeo el error
            guard let error = error else {
                return
            }
            // Manejo el error
            let handlerError = MLNHandlerError()
            handlerError.handlerError(error, controller: self)
        }
        
        // Largo el Service
        let service = MLNetworking()
        service.fetchUrl(with: url, onSuccess: onSuccess, onError: onError)
    }
    
    
    @IBAction func changeSearchOption(_ sender: UISegmentedControl) {
        selectedSortAlg = sender.selectedSegmentIndex
    }
    
    // MARK: Ordenamientos
    func ordenarPorTrack(array:[Track]) -> [Track] {
        var arrayToSort = array
        arrayToSort.sort(by: {
            (obj1, obj2) in
            let track1 = obj1 as Track
            let track2 = obj2 as Track
            return track1.trackName ?? "" < track2.trackName ?? ""
        })
        
        return arrayToSort
    }
    
    func ordenarPorFecha(array:[Track]) -> [Track] {
        var arrayToSort = array
        arrayToSort.sort(by: {
            (obj1, obj2) in
            let track1 = obj1 as Track
            let track2 = obj2 as Track
            
            let release1 = String.formattedDate(dateString: track1.releaseDate)
            let release2 = String.formattedDate(dateString: track2.releaseDate)
            
            
            guard let date1 = release1, let date2 = release2 else {
                return false
            }
            
            return date1 < date2
        })
        
        return arrayToSort
    }
    
    func ordenarInvertido(array:[Track]) -> [Track] {
        let reversedArray = array.reversed()
        return Array(reversedArray)
    }
    
}

