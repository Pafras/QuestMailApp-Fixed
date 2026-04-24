//
//  Models.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 19/04/26.
//

import Foundation

// MARK: - Schedule Section (Dynamic, Date-Based)

enum ScheduleSection: Hashable {
    case thisWeek
    case nextWeek
    case month(year: Int, month: Int)
    
    var title: String {
        switch self {
        case .thisWeek: return "This Week"
        case .nextWeek: return "Next Week"
        case .month(let year, let month):
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            if let date = Calendar.current.date(from: components) {
                return formatter.string(from: date)
            }
            return ""
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .thisWeek: return 0
        case .nextWeek: return 1
        case .month(let year, let month): return 2 + year * 12 + month
        }
    }
    
    static func from(date: Date) -> ScheduleSection {
        let cal = Calendar.current
        let now = Date()
        guard let thisWeekInterval = cal.dateInterval(of: .weekOfYear, for: now) else {
            let c = cal.dateComponents([.year, .month], from: date)
            return .month(year: c.year ?? 2026, month: c.month ?? 1)
        }
        let startOfNextWeek = cal.date(byAdding: .weekOfYear, value: 1, to: thisWeekInterval.start)!
        let endOfNextWeek = cal.date(byAdding: .weekOfYear, value: 1, to: startOfNextWeek)!
        
        if date < startOfNextWeek {
            return .thisWeek
        } else if date < endOfNextWeek {
            return .nextWeek
        } else {
            let c = cal.dateComponents([.year, .month], from: date)
            return .month(year: c.year ?? 2026, month: c.month ?? 1)
        }
    }
}

// MARK: - On Schedule Models

enum ParticipantType: String, Hashable {
    case open = "Open"
    case limited = "Limited"
}

struct ScheduledQuest: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let venue: String
    let scheduledDate: Date
    let iconName: String
    let participantType: ParticipantType
    let maxParticipants: Int?
    var rsvpCount: Int
    let activityDetail: String
    let reward: String
    let organizer: String
    
    // MARK: Formatted Display
    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "dd/MM"
        return f.string(from: scheduledDate)
    }
    
    var formattedTime: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: scheduledDate)
    }
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
    var reward: String = ""
    var date: Date = Date()
    var time: Date = Date()
    var participantType: ParticipantType = .open
    var maxParticipants: Int? = nil
}

struct RSVPResponse: Identifiable, Hashable {
    let id = UUID()
    let status: RSVPStatus
    let count: Int
}

// MARK: - Sample Data

struct SampleData {
    
    // MARK: Date Helper
    private static func makeDate(day: Int, month: Int, year: Int = 2026, hour: Int = 18, minute: Int = 0) -> Date {
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = day
        c.hour = hour
        c.minute = minute
        return Calendar.current.date(from: c) ?? Date()
    }

    // MARK: Scheduled Quests Array
    static let scheduledQuests: [ScheduledQuest] = [
        ScheduledQuest(
            title: "Finesse your first moves",
            venue: "Apple Dance Academy - Agung",
            scheduledDate: makeDate(day: 24, month: 4, hour: 18, minute: 0),
            iconName: "figure.dance",
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
            scheduledDate: makeDate(day: 25, month: 4, hour: 19, minute: 15),
            iconName: "sportscourt.fill",
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
            scheduledDate: makeDate(day: 26, month: 4, hour: 18, minute: 30),
            iconName: "figure.climbing",
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
            scheduledDate: makeDate(day: 30, month: 4, hour: 18, minute: 0),
            iconName: "gift.fill",
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
            scheduledDate: makeDate(day: 10, month: 5, hour: 19, minute: 45),
            iconName: "soccerball",
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
        ActivityPlan(title: "Taekwondo", organizer: "Richie - 8 Interested", interestedCount: 8, rsvpStatuses: [
            RSVPResponse(status: .yes, count: 3),
            RSVPResponse(status: .no, count: 2),
            RSVPResponse(status: .idk, count: 3),
        ]),
        ActivityPlan(title: "Apple Academy Marathon", organizer: "Marcus - 8 Interested", interestedCount: 8, rsvpStatuses: []),
        ActivityPlan(title: "Cooking Class Vol. 3", organizer: "Lewandowski - 8 Interested", interestedCount: 8, rsvpStatuses: []),
        ActivityPlan(title: "Jamming Apple Bali Band", organizer: "Bellingham - 8 Interested", interestedCount: 8, rsvpStatuses: []),
    ]
}
