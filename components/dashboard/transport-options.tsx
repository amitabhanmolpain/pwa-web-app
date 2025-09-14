"use client"

import { Card, CardContent } from "@/components/ui/card"
import { Bus, Car, Bike } from "lucide-react"

const transportOptions = [
  {
    id: "metro",
    name: "Metro",
    icon: Bus,
    color: "bg-blue-500",
    description: "Fast & Reliable",
  },
  {
    id: "intercity",
    name: "Intercity",
    icon: Car,
    color: "bg-green-500",
    description: "Long Distance",
  },
  {
    id: "rentals",
    name: "Rentals",
    icon: Bike,
    color: "bg-orange-500",
    description: "Flexible Options",
  },
]

export function TransportOptions() {
  return (
    <div className="space-y-4">
      <h2 className="text-xl font-semibold text-foreground">Transport Options</h2>

      <div className="grid grid-cols-3 lg:grid-cols-1 gap-4 lg:gap-3">
        {transportOptions.map((option) => {
          const IconComponent = option.icon
          return (
            <Card key={option.id} className="shadow-sm cursor-pointer hover:shadow-md transition-shadow">
              <CardContent className="p-4 text-center lg:text-left">
                <div className="lg:flex lg:items-center lg:space-x-4">
                  <div className={`${option.color} rounded-full p-3 mx-auto lg:mx-0 mb-3 lg:mb-0 w-fit`}>
                    <IconComponent className="w-6 h-6 text-white" />
                  </div>
                  <div>
                    <p className="font-medium text-card-foreground text-sm lg:text-base">{option.name}</p>
                    <p className="text-xs lg:text-sm text-muted-foreground mt-1">{option.description}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )
        })}
      </div>
    </div>
  )
}
