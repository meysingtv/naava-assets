import SwiftUI

class AppState: ObservableObject {
    @AppStorage("isOnboarded")    var isOnboarded:   Bool   = false
    @AppStorage("ownerName")      var ownerName:     String = ""
    @AppStorage("companyName")    var companyName:   String = ""
    @AppStorage("companyStreet")  var companyStreet: String = ""
    @AppStorage("companyCity")    var companyCity:   String = ""
    @AppStorage("companyPhone")   var companyPhone:  String = ""
    @AppStorage("companyEmail")   var companyEmail:  String = ""
    @AppStorage("companyTaxId")   var companyTaxId:  String = ""
    @AppStorage("selectedPlan")   var selectedPlanRaw: String = SubscriptionPlan.pro.rawValue

    var selectedPlan: SubscriptionPlan {
        SubscriptionPlan(rawValue: selectedPlanRaw) ?? .pro
    }

    var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Guten Morgen" }
        if h < 18 { return "Guten Tag" }
        return "Guten Abend"
    }

    var displayName: String { ownerName.isEmpty ? "Max" : ownerName }

    func completeOnboarding() { isOnboarded = true }

    func logout() { isOnboarded = false }
}
