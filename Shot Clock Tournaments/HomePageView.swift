
import Foundation
import SwiftUI
import StoreKit

struct HomePageView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    
    
    @State private var showAlert = false
    @State private var timer: Timer?
    @Environment(\.scenePhase) var scenePhase
        
    
    @StateObject var storeVM = StoreVM()
    @State var isPurchased = false
    @State private var triggerBuyAlert = false
    
    @State private var isLoadingSubscriptions = true
    @State private var appearing = false
    
    @StateObject var networkMonitor = NetworkMonitor()
    @State private var selectedProductID: Product? = nil
    
    @State var monthPriceSaved:Double = 0.0
    @State var sixMonthPriceSaved:Double = 0.0
    @State var yearPriceSaved:Double = 0.0
    @State var sixMonthDiscount:String = ""
    @State var yearDiscount:String = ""
    @State var minPrice = 1.0
    @State var timeInLoading = 0
    
    @State var monthMarketingTextAppearing = false
    @State var sixMonthMarketingTextAppearing = false
    @State var yearMarketingTextAppearing = false
    
    @State var feedbackAlert = false
    @State var moreAppsAlert = false
    @State var referralAlert = false
    @State var referralEmail1 = ""
    @State var referralEmail2 = ""
    @State var privacyAlert = false
    
    @State var backgroundColors:[Color] = generateRandomColorsFromPool()
        
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
            showAlert = true
        }
    }
    
    enum ShotClockSubscriptionPeriod: Hashable {
        case monthly(product: Product)
        case sixMonthly(product: Product)
        case yearly(product: Product)
        
        init?(product: Product) {
            let name = product.displayName.lowercased()
            
            if name.contains("1 mon") {
                self = .monthly(product: product)
            } else if name.contains("6") {
                self = .sixMonthly(product: product)
            } else if name.contains("year") {
                self = .yearly(product: product)
            } else {
                return nil // Return nil if no match is found
            }
        }
        
        var displayName: String {
            switch self {
            case .monthly(let product), .sixMonthly(let product), .yearly(let product):
                return product.displayName
            }
        }
        
        var price: String {
            switch self {
            case .monthly(let product), .sixMonthly(let product), .yearly(let product):
                return product.price.formatted(.currency(code: product.priceFormatStyle.currencyCode))
            }
        }
        
        var currency: String {
            switch self {
            case .monthly(let product), .sixMonthly(let product), .yearly(let product):
                return  product.priceFormatStyle.currencyCode
            }
        }
        
    }
    
    func loadDetailsFunction() {
        backgroundColors = generateRandomColorsFromPool()
        isPurchased = !storeVM.purchasedSubscriptions.isEmpty
        minPrice = NSDecimalNumber(decimal: storeVM.subscriptions.map({ $0.price }).min()!).doubleValue
        withAnimation(.smooth(duration: 1.5)){
            appearing = true
        }
    }
    
    var body: some View {
        
        NavigationStack{
            ZStack {
                
                if storeVM.subscriptions.isEmpty || !networkMonitor.isConnected {
//                    if !networkMonitor.isConnected {
                    //            if isLoadingSubscriptions || !networkMonitor.isConnected {
                    LayoutDimenions { properties in SplashScreenView(layoutProperties: properties) }
                        .onAppear {
                            startTimer()
                        }
                        .alert("Something's not right", isPresented: $showAlert) {
                            Button("Try again") {
                                startTimer()
                                loadDetailsFunction()
                            }
                            Button("Close App") {
                                exit(0)
                            }
                        } message: {
                            Text("Check your network and try again or close the app and open it again")
                        }
                    
                } else {
                    
                    backgroundMesh(sixColors: backgroundColors)
                        .ignoresSafeArea()
                        .onAppear(perform: {
                            timer?.invalidate()
                        })
                    
                    VStack {
                        
                        Spacer()
                        Image("logo no bg")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: UIScreen.main.bounds.height/5)
                        
                        Spacer()
                        
                        ScrollView{
                            SubscriptionStoreView(productIDs: ["monthlySub","sixMonthlySub","yearlySub"]) {
                                SubscriptionOptionGroupSet { product in
                                    ShotClockSubscriptionPeriod(product: product)!
                                } label: { product in
                                    Text("\(product.displayName)")
                                } marketingContent: {
                                    product in
                                    
                                    let name = product.displayName.lowercased()
                                    let dollars = extractCurrencyAmount(from: product.price)
                                    let animationTime = 0.8
                                    
                                    ZStack {
                                        
                                        if name.contains("1 mon") {
                                            VStack {
                                                Text("1 week free trial on any membership!")
                                                    .font(.title3)
                                                    .bold()
                                                    .foregroundStyle(.indigo)
                                                    .opacity(monthMarketingTextAppearing ? 1:0)
                                                    .onAppear{
                                                        withAnimation(.smooth(duration: animationTime)){
                                                            monthMarketingTextAppearing = true
                                                        }
                                                    }
                                                    .onDisappear{
                                                        monthMarketingTextAppearing = false
                                                    }
                                                Text("\(product.price)")
                                                    .foregroundStyle(.white)
                                            }
                                            .padding()
                                        } else if name.contains("6") {
                                            VStack{
                                                HStack{
                                                    Text("\(product.currency)\(String(format: "%.2f", (minPrice * 6 * 100).rounded() / 100))")
                                                        .strikethrough()
                                                        .foregroundColor(.white)
                                                        .opacity(sixMonthMarketingTextAppearing ? 1:0)
                                                    Text("Get \(sixMonthDiscount)% off!")
                                                        .font(.title3)
                                                        .foregroundStyle(.indigo)
                                                        .bold()
                                                        .opacity(sixMonthMarketingTextAppearing ? 1:0)
                                                        .onAppear{
                                                            withAnimation(.smooth(duration: animationTime)){
                                                                sixMonthMarketingTextAppearing = true
                                                            }
                                                            let percentDiscount = (100 * (minPrice*6.0 - dollars!) / (6.0*minPrice))
                                                            let roundedPercent = Int((percentDiscount * 10).rounded() / 10)
                                                            sixMonthDiscount = String("\(roundedPercent)")
                                                        }
                                                        .onDisappear{
                                                            sixMonthMarketingTextAppearing = false
                                                        }
                                                }
                                                Text("\(product.price)")
                                                    .foregroundStyle(.white)
                                            }
                                        } else if name.contains("year") {
                                            VStack {
                                                HStack{
                                                    Text("\(product.currency)\(String(format: "%.2f", (minPrice * 12 * 100).rounded() / 100))")
                                                        .strikethrough()
                                                        .foregroundColor(.white)
                                                        .opacity(yearMarketingTextAppearing ? 1:0)
                                                    Text("Get \(yearDiscount)% off!")
                                                        .font(.title2)
                                                        .foregroundStyle(.indigo)
                                                        .bold()
                                                        .opacity(yearMarketingTextAppearing ? 1:0)
                                                        .onAppear{
                                                            withAnimation(.smooth(duration: animationTime)){
                                                                yearMarketingTextAppearing = true
                                                            }
                                                            let percentDiscount = (100 * (minPrice*12.0 - dollars!) / (12.0*minPrice))
                                                            let roundedPercent = Int((percentDiscount * 10).rounded() / 10)
                                                            yearDiscount = String("\(roundedPercent)")
                                                            
                                                        }
                                                        .onDisappear{
                                                            yearMarketingTextAppearing = false
                                                        }
                                                }
                                                Text("\(product.price)")
                                                    .foregroundStyle(.white)
                                            }
                                        } else {
                                            
                                        }
                                    }
                                    
                                }
                            }
                            .storeButton(.hidden, for: .cancellation)
                            .tint(.indigo)
                            
                            Button {
                                privacyAlert = true
                            } label: {
                                Text("Privacy Policy and Terms of Use")
                                    .foregroundStyle(.white)
                                    .font(.subheadline)
                                    .bold()
                            }
                            .padding()
                            .alert("Privacy Policy and Terms of Use", isPresented: $privacyAlert, presenting: self) { _ in
                                Link("Terms of Use", destination: URL(string:"https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                Link("Privacy Policy", destination: URL(string: "https://www.freeprivacypolicy.com/live/b410d8f9-8ea2-4804-b3bc-31d8a30ac976")!)
                                Button("Cancel") {
                                    privacyAlert = false
                                }
                            } message: {
                                _ in
                                Text("Click to open link")
                            }
                            
                            Button {
                                Task {
                                    do {
                                        try await AppStore.sync()
                                    } catch {
                                        print(error)
                                    }
                                }
                            } label: {
                                Text("Restore purchases")
                                    .foregroundStyle(.white)
                                    .font(.subheadline)
                                    .bold()
                            }
                            
                        }
                        
                        Spacer()
                        
                        Grid {
                            GridRow {
                                VStack {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .resizable()
                                        .foregroundColor(.white)
                                        .aspectRatio(1, contentMode: .fit)
                                    Text("Feedback")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .onTapGesture {
                                    feedbackAlert = true
                                }
                                .alert("Got Feedback?", isPresented: $feedbackAlert, presenting: self) { _ in
                                    Link("Send us an email", destination: URL(string: "mailto:indigoappsnz@gmail.com?subject=Feedback")!)
                                    Link("Our Instagram Page", destination: URL(string: "https://www.instagram.com/shot_clock_app")!)
                                    Button("Close") {
                                        feedbackAlert = false
                                    }
                                } message: {
                                    _ in
                                    Text("We want to know.\n\nSend all feedback, good or bad, to indigoappsnz@gmail.com or our instagram page and we will do our best to get back to you ASAP.")
                                }
                                .frame(maxWidth: .infinity)
                                VStack{
                                    Image(systemName: "star.circle")
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fit)
                                        .foregroundStyle(.yellow)
                                    Text("More Apps")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .onTapGesture {
                                    moreAppsAlert = true
                                }
                                .alert("Like what you see?", isPresented: $moreAppsAlert, presenting: self) { _ in
                                    Link("Personal Shot Clock App", destination: URL(string:"https://apps.apple.com/nz/app/shot-clock-pool-snooker-timer/id6478100811")!)
                                    Link("Shot Clock Solo - Apple Watch", destination: URL(string:"https://apps.apple.com/nz/app/shot-clock-solo/id6502847918")!)
                                    Link("Our Instagram Page", destination: URL(string: "https://www.instagram.com/shot_clock_app")!)
                                    Button("Cancel") {
                                        moreAppsAlert = false
                                    }
                                    Button("Leave a Review") {
                                        requestReview()
                                    }
                                } message: {
                                    _ in
                                    Text("Check out our other apps and our pro ambassadors")
                                }
                                .frame(maxWidth: .infinity)
                                VStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .resizable()
                                        .aspectRatio(1.2, contentMode: .fit)
                                        .foregroundStyle(.indigo)
                                    Text("Referral Bonus")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .onTapGesture {
                                    referralAlert = true
                                }
                                .alert("Refer a friend!", isPresented: $referralAlert, presenting: self) { _ in
                                    Link("Email", destination: URL(string: "mailto:indigoappsnz@gmail.com?subject=Referral Request")!)
                                    Link("Instagram", destination: URL(string: "https://www.instagram.com/shot_clock_app")!)
                                    Button("Cancel") {
                                        referralAlert = false
                                    }
                                } message: {
                                    _ in
                                    Text("Get you and your friend a 10% discount by sending us both of your emails and your choice of subscriptions")
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: UIScreen.main.bounds.height/18.0)
                        
                        NavigationLink(destination: SelectTournamentManagerView()) {
                            Text("Continue")
                                .padding()
                                .background(storeVM.purchasedSubscriptions.isEmpty ? Color.gray:Color.indigo)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()
                        .disabled(storeVM.purchasedSubscriptions.isEmpty)
                        
                    }
                    .onAppear {
                        loadDetailsFunction()
                    }
                    .opacity(appearing ? 1:0)
                    .onDisappear {
                        appearing = false
                    }
                }
            }
        }
    }
    
    func buy(product: Product) async {
        do {
            if try await storeVM.purchase(product) != nil {
                isPurchased = true
                await storeVM.updateCustomerProductStatus()
            }
        } catch {
            print("purchase failed")
        }
    }
    
    func extractCurrencyAmount(from formattedString: String) -> Double? {
        // Define the regex pattern to match any currency symbol followed by a numeric value
        let pattern = "[^0-9,\\.]*([0-9,]+\\.?[0-9]*)"
        
        // Create a regex object
        let regex = try? NSRegularExpression(pattern: pattern)
        
        // Search for matches in the input string
        if let match = regex?.firstMatch(in: formattedString, range: NSRange(formattedString.startIndex..., in: formattedString)) {
            // Extract the matched substring (the numeric part)
            if let range = Range(match.range(at: 1), in: formattedString) {
                let matchedString = formattedString[range]
                
                // Remove commas (if any) and convert to Double
                let numericString = matchedString.replacingOccurrences(of: ",", with: "")
                return Double(numericString)
            }
        }
        
        // Return nil if no match is found
        return nil
    }

    
}


struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePageView()
    }
}
