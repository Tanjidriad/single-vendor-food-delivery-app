"use client";

import { useState, useCallback } from "react";
import { Sidebar } from "@/components/kds/sidebar";
import { Header } from "@/components/kds/header";
import { KanbanColumn, MobileTabSelector } from "@/components/kds/kanban-column";
import { MenuDrawer, MenuItem } from "@/components/kds/menu-drawer";
import { OrderHistory, CompletedOrder } from "@/components/kds/order-history";
import { Analytics } from "@/components/kds/analytics";
import { Settings } from "@/components/kds/settings";
import { Order, OrderStatus } from "@/components/kds/order-card";

// Sample order data
const initialOrders: Order[] = [
  {
    id: "8842",
    customerName: "Sarah M.",
    items: [
      { name: "Classic Cheeseburger", quantity: 2, modifiers: ["No Pickles", "Extra Cheese"] },
      { name: "Large Fries", quantity: 1 },
      { name: "Chocolate Shake", quantity: 2 },
    ],
    notes: ["NO ONIONS", "Allergy: Peanuts"],
    placedMinutesAgo: 2,
    deliveryType: "rider",
    platform: "UberEats",
    status: "new",
  },
  {
    id: "8843",
    customerName: "Mike T.",
    items: [
      { name: "Spicy Chicken Sandwich", quantity: 1 },
      { name: "Onion Rings", quantity: 1 },
      { name: "Diet Coke", quantity: 1 },
    ],
    placedMinutesAgo: 4,
    deliveryType: "rider",
    platform: "DoorDash",
    status: "new",
  },
  {
    id: "8844",
    customerName: "Lisa K.",
    items: [
      { name: "Garden Salad", quantity: 1, modifiers: ["Dressing on Side"] },
      { name: "Grilled Chicken Wrap", quantity: 1 },
    ],
    placedMinutesAgo: 12,
    isOverdue: true,
    deliveryType: "pickup",
    platform: "Direct",
    status: "new",
  },
  {
    id: "8839",
    customerName: "James R.",
    items: [
      { name: "Double Bacon Burger", quantity: 1, modifiers: ["Medium Rare"] },
      { name: "Sweet Potato Fries", quantity: 1 },
      { name: "Vanilla Shake", quantity: 1 },
    ],
    placedMinutesAgo: 8,
    deliveryType: "rider",
    platform: "UberEats",
    status: "in_progress",
  },
  {
    id: "8840",
    customerName: "Anna P.",
    items: [
      { name: "Fish Tacos", quantity: 3 },
      { name: "Guacamole & Chips", quantity: 1 },
      { name: "Margarita Lemonade", quantity: 2 },
    ],
    notes: ["Extra lime wedges"],
    placedMinutesAgo: 15,
    deliveryType: "rider",
    platform: "DoorDash",
    status: "in_progress",
  },
  {
    id: "8836",
    customerName: "Tom W.",
    items: [
      { name: "BBQ Pulled Pork Sandwich", quantity: 2 },
      { name: "Coleslaw", quantity: 2 },
      { name: "Iced Tea", quantity: 2 },
    ],
    placedMinutesAgo: 22,
    deliveryType: "pickup",
    platform: "Direct",
    status: "ready",
  },
  {
    id: "8837",
    customerName: "Emily C.",
    items: [
      { name: "Veggie Burger", quantity: 1, modifiers: ["Gluten-Free Bun"] },
      { name: "Side Salad", quantity: 1 },
    ],
    placedMinutesAgo: 18,
    deliveryType: "rider",
    platform: "UberEats",
    status: "ready",
  },
];

// Sample menu items
const initialMenuItems: MenuItem[] = [
  { id: "1", name: "Classic Cheeseburger", category: "Burgers", isAvailable: true },
  { id: "2", name: "Double Bacon Burger", category: "Burgers", isAvailable: true },
  { id: "3", name: "Veggie Burger", category: "Burgers", isAvailable: true },
  { id: "4", name: "Spicy Chicken Burger", category: "Burgers", isAvailable: false },
  { id: "5", name: "Spicy Chicken Sandwich", category: "Sandwiches", isAvailable: true },
  { id: "6", name: "Grilled Chicken Wrap", category: "Sandwiches", isAvailable: true },
  { id: "7", name: "BBQ Pulled Pork Sandwich", category: "Sandwiches", isAvailable: true },
  { id: "8", name: "Fish Tacos", category: "Specials", isAvailable: true },
  { id: "9", name: "Garden Salad", category: "Sides", isAvailable: true },
  { id: "10", name: "Large Fries", category: "Sides", isAvailable: true },
  { id: "11", name: "Sweet Potato Fries", category: "Sides", isAvailable: false },
  { id: "12", name: "Onion Rings", category: "Sides", isAvailable: true },
  { id: "13", name: "Chocolate Shake", category: "Drinks", isAvailable: true },
  { id: "14", name: "Vanilla Shake", category: "Drinks", isAvailable: true },
  { id: "15", name: "Diet Coke", category: "Drinks", isAvailable: true },
];

// Sample completed orders for history
const completedOrders: CompletedOrder[] = [
  {
    id: "8835",
    customerName: "John D.",
    items: [
      { name: "Classic Cheeseburger", quantity: 2 },
      { name: "Large Fries", quantity: 2 },
    ],
    total: 34.98,
    platform: "UberEats",
    deliveryType: "rider",
    completedAt: "Today, 2:45 PM",
    prepTime: 12,
    status: "completed",
  },
  {
    id: "8834",
    customerName: "Maria S.",
    items: [
      { name: "Fish Tacos", quantity: 2 },
      { name: "Guacamole & Chips", quantity: 1 },
    ],
    total: 28.50,
    platform: "DoorDash",
    deliveryType: "rider",
    completedAt: "Today, 2:30 PM",
    prepTime: 15,
    status: "completed",
  },
  {
    id: "8833",
    customerName: "Robert K.",
    items: [{ name: "Double Bacon Burger", quantity: 1 }],
    total: 15.99,
    platform: "Direct",
    deliveryType: "pickup",
    completedAt: "Today, 2:15 PM",
    prepTime: 10,
    status: "completed",
  },
  {
    id: "8832",
    customerName: "Jessica L.",
    items: [
      { name: "Garden Salad", quantity: 1 },
      { name: "Iced Tea", quantity: 1 },
    ],
    total: 12.50,
    platform: "UberEats",
    deliveryType: "rider",
    completedAt: "Today, 1:50 PM",
    prepTime: 8,
    status: "completed",
  },
  {
    id: "8831",
    customerName: "David M.",
    items: [{ name: "Veggie Burger", quantity: 1 }],
    total: 13.99,
    platform: "DoorDash",
    deliveryType: "rider",
    completedAt: "Today, 1:30 PM",
    prepTime: 11,
    status: "cancelled",
  },
  {
    id: "8830",
    customerName: "Amanda T.",
    items: [
      { name: "BBQ Pulled Pork Sandwich", quantity: 2 },
      { name: "Coleslaw", quantity: 2 },
    ],
    total: 29.98,
    platform: "Direct",
    deliveryType: "pickup",
    completedAt: "Today, 1:15 PM",
    prepTime: 14,
    status: "completed",
  },
  {
    id: "8829",
    customerName: "Chris B.",
    items: [
      { name: "Spicy Chicken Sandwich", quantity: 1 },
      { name: "Onion Rings", quantity: 1 },
    ],
    total: 18.50,
    platform: "UberEats",
    deliveryType: "rider",
    completedAt: "Yesterday, 8:30 PM",
    prepTime: 13,
    status: "completed",
  },
  {
    id: "8828",
    customerName: "Nicole R.",
    items: [
      { name: "Classic Cheeseburger", quantity: 3 },
      { name: "Large Fries", quantity: 3 },
      { name: "Chocolate Shake", quantity: 3 },
    ],
    total: 52.47,
    platform: "DoorDash",
    deliveryType: "rider",
    completedAt: "Yesterday, 7:45 PM",
    prepTime: 18,
    status: "completed",
  },
  {
    id: "8827",
    customerName: "Kevin P.",
    items: [{ name: "Fish Tacos", quantity: 4 }],
    total: 39.96,
    platform: "Direct",
    deliveryType: "pickup",
    completedAt: "Yesterday, 7:00 PM",
    prepTime: 16,
    status: "refunded",
  },
];

export default function KitchenDashboard() {
  const [orders, setOrders] = useState<Order[]>(initialOrders);
  const [menuItems, setMenuItems] = useState<MenuItem[]>(initialMenuItems);
  const [activeNavIndex, setActiveNavIndex] = useState(0);
  const [isOnline, setIsOnline] = useState(true);
  const [isBusyMode, setIsBusyMode] = useState(false);
  const [isMenuDrawerOpen, setIsMenuDrawerOpen] = useState(false);
  const [mobileActiveTab, setMobileActiveTab] = useState(0);

  // Filter orders by status
  const newOrders = orders.filter((o) => o.status === "new");
  const inProgressOrders = orders.filter((o) => o.status === "in_progress");
  const readyOrders = orders.filter((o) => o.status === "ready");

  // Handle order status progression
  const handleOrderAction = useCallback((orderId: string) => {
    setOrders((prev) =>
      prev.map((order) => {
        if (order.id !== orderId) return order;
        const nextStatus: Record<OrderStatus, OrderStatus | null> = {
          new: "in_progress",
          in_progress: "ready",
          ready: null,
        };
        const next = nextStatus[order.status];
        if (next === null) {
          return order;
        }
        return { ...order, status: next };
      }).filter((order) => {
        if (order.id === orderId && order.status === "ready") {
          return false;
        }
        return true;
      })
    );
  }, []);

  // Handle print
  const handlePrintOrder = useCallback((orderId: string) => {
    console.log("Printing order:", orderId);
  }, []);

  // Toggle busy mode
  const handleToggleBusyMode = useCallback(() => {
    setIsBusyMode((prev) => !prev);
  }, []);

  // Handle store status change
  const handleStatusChange = useCallback((status: string) => {
    setIsOnline(status !== "closed");
  }, []);

  // Handle navigation
  const handleNavigate = useCallback((index: number) => {
    setActiveNavIndex(index);
    // Open menu drawer when clicking on Menu/86 List
    if (index === 2) {
      setIsMenuDrawerOpen(true);
    }
  }, []);

  // Toggle menu item availability
  const handleToggleMenuAvailability = useCallback((itemId: string) => {
    setMenuItems((prev) =>
      prev.map((item) =>
        item.id === itemId ? { ...item, isAvailable: !item.isAvailable } : item
      )
    );
  }, []);

  // Render main content based on active navigation
  const renderMainContent = () => {
    switch (activeNavIndex) {
      case 0: // Active Orders
        return (
          <>
            {/* Mobile Tab Selector */}
            <MobileTabSelector
              activeTab={mobileActiveTab}
              onTabChange={setMobileActiveTab}
              counts={{
                new: newOrders.length,
                inProgress: inProgressOrders.length,
                ready: readyOrders.length,
              }}
            />

            {/* Kanban Board */}
            <main className="flex-1 p-3 md:p-6 flex gap-3 md:gap-6 overflow-hidden">
              <KanbanColumn
                title="New Orders"
                orders={newOrders}
                accentColor="success"
                onOrderAction={handleOrderAction}
                onPrintOrder={handlePrintOrder}
                isMobileActive={mobileActiveTab === 0}
              />
              <KanbanColumn
                title="In Progress"
                orders={inProgressOrders}
                accentColor="warning"
                onOrderAction={handleOrderAction}
                onPrintOrder={handlePrintOrder}
                isMobileActive={mobileActiveTab === 1}
              />
              <KanbanColumn
                title="Ready for Pickup"
                orders={readyOrders}
                accentColor="info"
                onOrderAction={handleOrderAction}
                onPrintOrder={handlePrintOrder}
                isMobileActive={mobileActiveTab === 2}
              />
            </main>
          </>
        );
      case 1: // Order History
        return <OrderHistory orders={completedOrders} />;
      case 2: // 86 List (handled by drawer)
        return (
          <>
            <MobileTabSelector
              activeTab={mobileActiveTab}
              onTabChange={setMobileActiveTab}
              counts={{
                new: newOrders.length,
                inProgress: inProgressOrders.length,
                ready: readyOrders.length,
              }}
            />
            <main className="flex-1 p-3 md:p-6 flex gap-3 md:gap-6 overflow-hidden">
              <KanbanColumn
                title="New Orders"
                orders={newOrders}
                accentColor="success"
                onOrderAction={handleOrderAction}
                onPrintOrder={handlePrintOrder}
                isMobileActive={mobileActiveTab === 0}
              />
              <KanbanColumn
                title="In Progress"
                orders={inProgressOrders}
                accentColor="warning"
                onOrderAction={handleOrderAction}
                onPrintOrder={handlePrintOrder}
                isMobileActive={mobileActiveTab === 1}
              />
              <KanbanColumn
                title="Ready for Pickup"
                orders={readyOrders}
                accentColor="info"
                onOrderAction={handleOrderAction}
                onPrintOrder={handlePrintOrder}
                isMobileActive={mobileActiveTab === 2}
              />
            </main>
          </>
        );
      case 3: // Analytics
        return <Analytics />;
      case 4: // Settings
        return <Settings />;
      default:
        return null;
    }
  };

  return (
    <div className="h-screen flex overflow-hidden">
      {/* Sidebar */}
      <Sidebar activeIndex={activeNavIndex} onNavigate={handleNavigate} />

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0 pb-16 md:pb-0">
        {/* Header */}
        <Header
          restaurantName="Burger Palace"
          isOnline={isOnline}
          isBusyMode={isBusyMode}
          onToggleBusyMode={handleToggleBusyMode}
          onStatusChange={handleStatusChange}
          onOpenMenu={() => setIsMenuDrawerOpen(true)}
        />

        {/* Main Content Area */}
        {renderMainContent()}
      </div>

      {/* Menu Availability Drawer */}
      <MenuDrawer
        isOpen={isMenuDrawerOpen}
        onClose={() => setIsMenuDrawerOpen(false)}
        items={menuItems}
        onToggleAvailability={handleToggleMenuAvailability}
      />
    </div>
  );
}
