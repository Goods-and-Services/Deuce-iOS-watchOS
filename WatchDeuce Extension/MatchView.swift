//
//  MatchView.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 2/4/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct MatchView: View {
    @EnvironmentObject var userData: UserData
    
    @State var match: Match
    @State var singlesServiceAlert = true
    @State var showingNamesSheet = false
    @State var showingMatchMenu = false
    
    @State var cloudController = CloudController()
    
    @Binding var matchInProgress: Bool
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                PlayerTwo(match: self.$match)
                .frame(maxHeight: geometry.size.height / 2)
                
                Divider()
                
                PlayerOne(match: self.$match)
                .frame(maxHeight: geometry.size.height / 2)
            }
            
            HStack {
                Button(action: {
                    matchInProgress.toggle()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title)
                }
                .buttonStyle(PlainButtonStyle())
                .environmentObject(userData)
                .onAppear() {
                    self.match.stop()
                    self.cloudController.uploadToCloud(match: self.$match.wrappedValue)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(false)
                
                Group {
                    Image(systemName: "arrow.down")
                    Spacer()
                    Image(systemName: "arrow.up")
                }
                .foregroundColor(self.match.isChangeover() && self.match.state == .playing ? .secondary : .clear)
                
                Button(action: {
                    showingMatchMenu.toggle()
                }) {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(height: geometry.size.height)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .font(.largeTitle)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle(match.state == .playing ? LocalizedStringKey(title()) : "")
        .edgesIgnoringSafeArea(.bottom)
        .alert(isPresented: $singlesServiceAlert) {
            Alert(title: Text(LocalizedStringKey(serviceQuestion())),
                  primaryButton: .default(Text(LocalizedStringKey("You"))) {
                    self.match.servicePlayer = .playerOne
                    self.userData.workout.startWorkout()
                },
                  secondaryButton: .default(Text("Opponent")) {
                    self.match.servicePlayer = .playerTwo
                    self.userData.workout.startWorkout()
                })
        }
        .sheet(isPresented: $showingMatchMenu) {
            MatchMenu(match: $match, singlesServiceAlert: $singlesServiceAlert, showingMatchMenu: $showingMatchMenu, cloudController: $cloudController, matchInProgress: $matchInProgress)
        }
    }
    
    func serviceQuestion() -> String {
        switch match.format {
        case .doubles:
            return "Which team will serve first?"
        default:
            return "Who will serve first?"
        }
    }
    
    func title() -> String {
        if match.currentSet.currentGame.pointsWon == [0, 0] {
            if match.isSupertiebreak { return "Supertiebreak" }
            if match.currentSet.currentGame.isTiebreak { return "Tiebreak" }
        }
        if match.isMatchPoint() { return "Match Point" }
        if match.currentSet.isSetPoint() { return "Set Point" }
        if match.currentSet.currentGame.currentPoint.isBreakpoint { return "Break Point" }
        return ""
    }
}

// MARK: - Opponent
struct PlayerTwo: View {
    @Binding var match: Match
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                self.match.scorePoint(for: .playerTwo)
                WKInterfaceDevice.current().play(self.match.isChangeover() ? .stop : .start)
            }) {
                VStack(spacing: 0) {
                    ZStack() {
                        self.playerTwoServiceImage()
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .foregroundColor(self.match.servicePlayer == .playerTwo && match.state == .playing ? .green : .clear)
                    .frame(width: geometry.size.width / 2, alignment: self.playerTwoServiceAlignment())
                    .animation(self.match.currentSet.currentGame.pointsPlayed > 0 && !self.match.currentSet.currentGame.isTiebreak ? .default : nil)
                    
                    Text(LocalizedStringKey(self.match.state == .finished ? self.playerTwoMedal() : self.playerTwoGameScore()))
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    
                    HStack {
                        ForEach(self.match.sets, id: \.self) { set in
                            Text(set.getScore(for: .playerTwo))
                        }
                    }
                    .font(Font.title.monospacedDigit())
                    .minimumScaleFactor(0.7)
                    .animation(match.allPointsPlayed.count > 0 ? .default : .none)
                }
                .frame(height: geometry.size.height)
            }
            .disabled(match.state == .finished ? true : false)
        }
    }
    
    func playerTwoServiceAlignment() -> Alignment {
        if match.format == .noAd && match.currentSet.currentGame.pointsWon == [3, 3] && !match.currentSet.currentGame.isTiebreak {
            return .center
        } else {
            switch match.currentSet.currentGame.serviceSide {
            case .deuceCourt:
                return .leading
            case .adCourt:
                return .trailing
            }
        }
    }
    
    func playerTwoGameScore() -> String {
        switch (match.currentSet.currentGame.advantage(), match.servicePlayer) {
        case (.playerTwo, .playerOne):
            return "Ad out"
        case (.playerTwo, .playerTwo):
            return "Ad in"
        case (.playerOne, _):
            return " "
        default:
            switch match.currentSet.currentGame.isTiebreak {
            case true:
                return String(match.currentSet.currentGame.pointsWon[1])
            case false:
                return match.currentSet.currentGame.score(for: .playerTwo)
            }
        }
    }
    
    func playerTwoServiceImage() -> Image {
        Image(systemName: "circle.fill")
    }
    
    func playerTwoMedal() -> String {
        switch match.winner! {
        case .playerOne:
            return " "
        case .playerTwo:
            return "🏆"
        }
    }
}

// MARK: - User
struct PlayerOne: View {
    @Binding var match: Match
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                self.match.scorePoint(for: .playerOne)
                WKInterfaceDevice.current().play(self.match.isChangeover() ? .stop : .start)
            }) {
                VStack(spacing: 0) {
                    HStack {
                        ForEach(self.match.sets, id: \.self) { set in
                            Text(set.getScore(for: .playerOne))
                        }
                    }
                    .font(Font.title.monospacedDigit())
                    .minimumScaleFactor(0.7)
                    .animation(match.allPointsPlayed.count > 0 ? .default : .none)
                    
                    Text(LocalizedStringKey(self.match.state == .finished ? self.playerOneMedal() : self.playerOneGameScore()))
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    
                    ZStack {
                        self.playerOneServiceImage()
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .foregroundColor(self.match.servicePlayer == .playerOne && match.state == .playing ? .green : .clear)
                    .frame(width: geometry.size.width / 2, alignment: self.playerOneServiceAlignment())
                    .animation(self.match.currentSet.currentGame.pointsPlayed > 0 && !self.match.currentSet.currentGame.isTiebreak ? .default : nil)
                }
                .frame(height: geometry.size.height)
            }
            .disabled(match.state == .finished ? true : false)
        }
    }
    
    func playerOneServiceAlignment() -> Alignment {
        if match.format == .noAd && match.currentSet.currentGame.pointsWon == [3, 3] && !match.currentSet.currentGame.isTiebreak {
            return .center
        } else {
            switch match.currentSet.currentGame.serviceSide {
            case .deuceCourt:
                return .trailing
            case .adCourt:
                return .leading
            }
        }
    }
    
    func playerOneGameScore() -> String {
        switch (match.currentSet.currentGame.advantage(), match.servicePlayer) {
        case (.playerOne, .playerOne):
            return "Ad in"
        case (.playerOne, .playerTwo):
            return "Ad out"
        case (.playerTwo, _):
            return " "
        default:
            switch match.currentSet.currentGame.isTiebreak {
            case true:
                return String(match.currentSet.currentGame.pointsWon[0])
            case false:
                return match.currentSet.currentGame.score(for: .playerOne)
            }
        }
    }
    
    func playerOneServiceImage() -> Image {
        Image(systemName: "circle.fill")
    }
    
    func playerOneMedal() -> String {
        switch match.winner! {
        case .playerOne:
            return "🏆"
        case .playerTwo:
            return " "
        }
    }
}

struct MatchView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        let format = userData.formats[0]
        return Group {
            MatchView(match: Match(format: format), matchInProgress: .constant(true))
                .environmentObject(userData)
                .environment(\.locale, .init(identifier: "en"))
        }
    }
}
