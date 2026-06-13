"use client"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

const activityData = [
  {
    id: 1,
    user: "John Doe",
    action: "placed a new order",
    target: "#ORD-8924",
    time: "2 mins ago",
    initials: "JD",
  },
  {
    id: 2,
    user: "Burger King Banani",
    action: "accepted order",
    target: "#ORD-8923",
    time: "5 mins ago",
    initials: "BK",
  },
  {
    id: 3,
    user: "System",
    action: "flagged a delayed delivery",
    target: "Rider Ali",
    time: "12 mins ago",
    initials: "SY",
  },
  {
    id: 4,
    user: "Sarah Smith",
    action: "registered as a new customer",
    target: "",
    time: "1 hour ago",
    initials: "SS",
  },
  {
    id: 5,
    user: "Pizza Hut",
    action: "updated their menu",
    target: "",
    time: "2 hours ago",
    initials: "PH",
  },
]

export function ActivityFeed() {
  return (
    <div className="space-y-6 w-full h-full overflow-y-auto pr-4">
      {activityData.map((activity) => (
        <div key={activity.id} className="flex items-center gap-4">
          <Avatar className="h-9 w-9 border border-border/50">
            <AvatarImage src="" alt={activity.user} />
            <AvatarFallback className="bg-primary/10 text-primary text-xs font-medium">
              {activity.initials}
            </AvatarFallback>
          </Avatar>
          <div className="flex flex-col flex-1 space-y-1">
            <p className="text-sm leading-none">
              <span className="font-medium text-foreground">{activity.user}</span>{" "}
              <span className="text-muted-foreground">{activity.action}</span>{" "}
              {activity.target && (
                <span className="font-medium text-foreground">{activity.target}</span>
              )}
            </p>
            <p className="text-xs text-muted-foreground">{activity.time}</p>
          </div>
        </div>
      ))}
    </div>
  )
}
