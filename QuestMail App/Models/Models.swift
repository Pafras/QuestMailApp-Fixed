//
//  Models.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 19/04/26.
//

import Foundation

// MARK: - On Schedule Models

enum QuestSection: String, CaseIterable {
    case thisWeek = "This Week"
    case nextWeek = "Next Week"
}

enum ParticipantType: String, Hashable {
    case open = "Open"
    case limited = "Limited"
}

struct ScheduledQuest: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let venue: String
    let date: String
    let time: String
    let iconName: String
    let section: QuestSection
    let participantType: ParticipantType
    let maxParticipants: Int?
    var rsvpCount: Int
    // LATER: these will be passed from ComposeActivityCard when planning → scheduled is wired up
    let activityDetail: String      // maps to ACTIVITY field in ComposeActivityCard
    let reward: String              // maps to WHAT YOU'LL WALK AWAY WITH
    let organizer: String           // maps to WHO / Hosted by
}

// MARK: - Desires Models

struct DesireActivity: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    var wantCount: Int
    let iconName: String
    let iconColor: String
}

// MARK: - Activity Planning Models

enum RSVPStatus: String, CaseIterable {
    case yes = "Yes"
    case no = "No"
    case idk = "Idk"
}

struct ActivityPlan: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let organizer: String
    let interestedCount: Int
    let rsvpStatuses: [RSVPResponse]
    var activity: String = ""
    var place: String = ""
}

struct RSVPResponse: Identifiable, Hashable {
    let id = UUID()
    let status: RSVPStatus
    let count: Int
}

// MARK: - Sample Data (Array of Instances)

struct SampleData {

    // MARK: Scheduled Quests Array
    static let scheduledQuests: [ScheduledQuest] = [
        ScheduledQuest(
            title: "Finesse your first moves",
            venue: "Apple Dance Academy - Agung",
            date: "19/04", time: "6 pm",
            iconName: "figure.dance",
            section: .thisWeek,
            participantType: .open,
            maxParticipants: nil,
            rsvpCount: 5,
            activityDetail: "A beginner-friendly Latin dance session covering basic salsa footwork and partner movement.",
            reward: "You'll walk away knowing your first 3 salsa moves and feeling less awkward on the dancefloor.",
            organizer: "Pafras"
        ),
        ScheduledQuest(
            title: "Futsal",
            venue: "Apple Futsal Academy - Arjuna Court",
            date: "16/04", time: "7 pm",
            iconName: "sportscourt.fill",
            section: .thisWeek,
            participantType: .limited,
            maxParticipants: 14,
            rsvpCount: 10,
            activityDetail: "Casual 5v5 futsal. Balanced teams will be sorted on the day.",
            reward: "A solid sweat, bragging rights, and maybe a post-game drink.",
            organizer: "Agung"
        ),
        ScheduledQuest(
            title: "Bouldering",
            venue: "Apple Bouldering Academy - Canggu",
            date: "18/04", time: "6 pm",
            iconName: "figure.climbing",
            section: .thisWeek,
            participantType: .limited,
            maxParticipants: 8,
            rsvpCount: 6,
            activityDetail: "Indoor bouldering for all levels. Instructors on hand for first-timers.",
            reward: "Upper body gains and a new hobby that will haunt your weekend plans.",
            organizer: "Pafras"
        ),
        ScheduledQuest(
            title: "Pafras's Birthday",
            venue: "Filadelfia Sushi Kerobokan",
            date: "14/20", time: "6 pm",
            iconName: "gift.fill",
            section: .nextWeek,
            participantType: .open,
            maxParticipants: nil,
            rsvpCount: 12,
            activityDetail: "Dinner to celebrate Pafras turning another year older and somehow wiser.",
            reward: "Good food, good people, and a free excuse to skip the gym.",
            organizer: "Pafras"
        ),
        ScheduledQuest(
            title: "UCL Final",
            venue: "Sports Bar - Seminyak",
            date: "14/20", time: "6 pm",
            iconName: "soccerball",
            section: .nextWeek,
            participantType: .limited,
            maxParticipants: 20,
            rsvpCount: 18,
            activityDetail: "Watching the UEFA Champions League Final together. Jerseys encouraged.",
            reward: "Shared suffering or shared glory, depending on who makes the final.",
            organizer: "Agung"
        ),
    ]
    
    // MARK: Desire Activities Array
    static let desireActivities: [DesireActivity] = [
        DesireActivity(title: "Salsa Dance", subtitle: "Pafras", wantCount: 12, iconName: "triangle.fill", iconColor: "orange"),
        DesireActivity(title: "Mini Soccer", subtitle: "", wantCount: 12, iconName: "triangle.fill", iconColor: "orange"),
        DesireActivity(title: "Self Defence Class", subtitle: "", wantCount: 12, iconName: "triangle.fill", iconColor: "yellow"),
        DesireActivity(title: "Weekly Board Games", subtitle: "", wantCount: 4, iconName: "triangle.fill", iconColor: "yellow"),
        DesireActivity(title: "Animation", subtitle: "", wantCount: 7, iconName: "triangle.fill", iconColor: "cyan"),
        DesireActivity(title: "Balinese Music Lesson", subtitle: "", wantCount: 4, iconName: "triangle.fill", iconColor: "cyan"),
        DesireActivity(title: "Book Sharing", subtitle: "", wantCount: 7, iconName: "triangle.fill", iconColor: "cyan"),
        DesireActivity(title: "Monthly FIFA Tournament", subtitle: "", wantCount: 4, iconName: "triangle.fill", iconColor: "cyan"),
    ]

    // MARK: Activity Plans Array
    static let activityPlans: [ActivityPlan] = [
        ActivityPlan(title: "Self-defense introduction", organizer: "Pafras - 8 Interested", interestedCount: 8, rsvpStatuses: [
            RSVPResponse(status: .yes, count: 3),
            RSVPResponse(status: .no, count: 2),
            RSVPResponse(status: .idk, count: 3),
        ]),
        ActivityPlan(title: "Self-defense introduction", organizer: "Pafras - 8 Interested", interestedCount: 8, rsvpStatuses: []),
        ActivityPlan(title: "Self-defense introduction", organizer: "Pafras - 8 Interested", interestedCount: 8, rsvpStatuses: []),
        ActivityPlan(title: "Self-defense introduction", organizer: "Pafras - 8 Interested", interestedCount: 8, rsvpStatuses: []),
    ]
}
