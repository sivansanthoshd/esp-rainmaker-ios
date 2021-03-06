// Copyright 2020 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  SelectDevicesViewController.swift
//  ESPRainMaker
//
#if SCHEDULE
    import UIKit

    class SelectDevicesViewController: UIViewController, ScheduleActionDelegate {
        @IBOutlet var tableView: UITableView!
        var availableDeviceCopy: [Device]!
        var selectedIndexPath: [IndexPath] = []

        override func viewDidLoad() {
            super.viewDidLoad()

            // Do any additional setup after loading the view.
            tableView.register(UINib(nibName: "ScheduleSwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "scheduleSwitchTVC")
            tableView.register(UINib(nibName: "ScheduleGenericTableViewCell", bundle: nil), forCellReuseIdentifier: "scheduleGenericTVC")
            tableView.register(UINib(nibName: "DeviceHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "deviceHV")
            tableView.register(UINib(nibName: "ScheduleSliderTableViewCell", bundle: nil), forCellReuseIdentifier: "scheduleSliderTableViewCell")
        }

        // MARK: - IBActions

        @IBAction func cancelButtonPressed(_: Any) {
            navigationController?.popViewController(animated: true)
            ESPScheduler.shared.configureDeviceForCurrentSchedule()
        }

        @IBAction func doneButtonPressed(_: Any) {
            navigationController?.popViewController(animated: true)
        }

        // MARK: - ScheduleActionDelegate

        func headerViewDidTappedFor(section: Int) {
            availableDeviceCopy[section].collapsed = !availableDeviceCopy[section].collapsed
            tableView.reloadSections(IndexSet(arrayLiteral: section), with: .automatic)
        }

        func paramStateChangedat(indexPath: IndexPath) {
            tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
        }

        // MARK: - Private Methods

        private func getTableViewCellBasedOn(indexPath: IndexPath) -> UITableViewCell {
            let device = availableDeviceCopy[indexPath.section]
            let param = device.params![indexPath.row]
            if param.uiType == "esp.ui.slider" {
                if let dataType = param.dataType?.lowercased(), dataType == "int" || dataType == "float" {
                    if let bounds = param.bounds {
                        let maxValue = bounds["max"] as? Float ?? 100
                        let minValue = bounds["min"] as? Float ?? 0
                        if minValue < maxValue {
                            let cell = tableView.dequeueReusableCell(withIdentifier: "scheduleSliderTableViewCell", for: indexPath) as! ScheduleSliderTableViewCell
                            if let bounds = param.bounds {
                                cell.slider.minimumValue = bounds["min"] as? Float ?? 0
                                cell.slider.maximumValue = bounds["max"] as? Float ?? 100
                            }
                            if param.dataType!.lowercased() == "int" {
                                let value = param.value as? Int ?? 0
                                cell.minLabel.text = "\(Int(cell.slider.minimumValue))"
                                cell.maxLabel.text = "\(Int(cell.slider.maximumValue))"
                                cell.slider.value = Float(value)
                            } else {
                                cell.minLabel.text = "\(cell.slider.minimumValue)"
                                cell.maxLabel.text = "\(cell.slider.maximumValue)"
                                cell.slider.value = param.value as! Float
                            }
                            cell.param = param
                            cell.title.text = param.name ?? ""
                            if param.selected {
                                cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
                                cell.slider.isEnabled = true
                            } else {
                                cell.checkButton.setImage(UIImage(named: "unselected"), for: .normal)
                                cell.slider.isEnabled = false
                            }
                            cell.device = device
                            cell.delegate = self
                            cell.indexPath = indexPath
                            return cell
                        }
                    }
                }
            } else if param.uiType == "esp.ui.toggle", param.dataType?.lowercased() == "bool" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "scheduleSwitchTVC", for: indexPath) as! ScheduleSwitchTableViewCell
                cell.controlName.text = param.name?.deletingPrefix(device.name!)
                cell.param = param

                if let switchState = param.value as? Bool {
                    if switchState {
                        cell.controlStateLabel.text = "On"
                    } else {
                        cell.controlStateLabel.text = "Off"
                    }
                    cell.toggleSwitch.setOn(switchState, animated: true)
                }
                cell.toggleSwitch.isEnabled = true
                if param.selected {
                    cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
                    cell.toggleSwitch.isEnabled = true
                } else {
                    cell.checkButton.setImage(UIImage(named: "unselected"), for: .normal)
                    cell.toggleSwitch.isEnabled = false
                }
                cell.device = device
                cell.delegate = self
                cell.indexPath = indexPath
                return cell
            }

            return getTableViewGenericCell(param: param, indexPath: indexPath)
        }

        private func getTableViewGenericCell(param: Param, indexPath: IndexPath) -> ScheduleGenericTableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "scheduleGenericTVC", for: indexPath) as! ScheduleGenericTableViewCell
            cell.device = availableDeviceCopy[indexPath.section]
            cell.delegate = self
            cell.indexPath = indexPath
            cell.controlName.text = param.name
            if let value = param.value {
                cell.controlValue = "\(value)"
            }
            cell.controlValueLabel.text = cell.controlValue
            if let data_type = param.dataType {
                cell.dataType = data_type
            }
            cell.param = param
            cell.backView.backgroundColor = UIColor.white
            if param.selected {
                cell.checkButton.setImage(UIImage(named: "selected"), for: .normal)
                cell.editButton.isHidden = false
            } else {
                cell.checkButton.setImage(UIImage(named: "unselected"), for: .normal)
                cell.editButton.isHidden = true
            }
            return cell
        }
    }

    extension SelectDevicesViewController: UITableViewDelegate {
        func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
            return 60.5
        }

        func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
            return UITableView.automaticDimension
        }

        func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
            return 25.0
        }
    }

    extension SelectDevicesViewController: UITableViewDataSource {
        func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
            if availableDeviceCopy[section].collapsed {
                return 0
            }
            return availableDeviceCopy[section].params?.count ?? 0
        }

        func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = getTableViewCellBasedOn(indexPath: indexPath)
            return cell
        }

        func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "deviceHV") as! DeviceHeaderView
            let device = availableDeviceCopy[section]
            headerView.deviceLabel.text = device.deviceName
            headerView.section = section
            headerView.device = device
            headerView.delegate = self
            if device.collapsed {
                headerView.arrowImageView.image = UIImage(named: "right_arrow")
            } else {
                headerView.arrowImageView.image = UIImage(named: "down_arrow")
            }
            if device.selectedParams == 0 {
                headerView.selectDeviceButton.setImage(UIImage(named: "checkbox_unselect"), for: .normal)
            } else if device.selectedParams == device.params?.count {
                headerView.selectDeviceButton.setImage(UIImage(named: "checkbox_select"), for: .normal)
            } else {
                headerView.selectDeviceButton.setImage(UIImage(named: "checkbox_partial"), for: .normal)
            }
            return headerView
        }

        func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
            let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
            footerView.backgroundColor = UIColor.clear
            return footerView
        }

        func numberOfSections(in _: UITableView) -> Int {
            return availableDeviceCopy.count
        }
    }
#endif
