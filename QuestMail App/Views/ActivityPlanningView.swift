//
//  ActivityPlanningView.swift
//  QuestMail App
//
//  Created by Pafras Vio Prayogo on 19/04/26.
//

import SwiftUI

// MARK: - ActivityPlanningView
struct ActivityPlanningView: View {
    let plans: [ActivityPlan]
    @Binding var selectedPlan: ActivityPlan?
    
    // MARK: Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: Section Header
                Text("Being Organized")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // MARK: Plan Rows
                ForEach(plans) { plan in
                    ActivityPlanRow(plan: plan)
                        .onTapGesture {
                            selectedPlan = plan
                        }
                    Divider()
                        .padding(.horizontal)
                }
 
                // MARK: Footer Note
                Spacer()
                    .frame(height: 60)

                HStack {
                    Spacer()
                    Text("When all details are set,\nevents move to On Schedule")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - ActivityPlanRow (Single Plan Item)
struct ActivityPlanRow: View {
    let plan: ActivityPlan

    // MARK: Properties
    private let detailTags = ["Who", "Time", "Spot"]

    // MARK: Body
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                // MARK: Title
                Text(plan.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // MARK: Organizer
                Text("by \(plan.organizer)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // MARK: Detail Tags (Who, Time, Spot)
                HStack(spacing: 8) {
                    ForEach(detailTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.mint.opacity(0.15))
                            )
                    }
                }
                .padding(.top, 2)
            }

            Spacer()

            // MARK: Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview
#Preview {
    ActivityPlanningView(plans: SampleData.activityPlans, selectedPlan: .constant(nil))
}
