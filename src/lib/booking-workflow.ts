export type BookingAction = { status: string; label: string }

const providerActions: Record<string, BookingAction> = {
  confirmed: { status: "accepted", label: "Terima pekerjaan" },
  accepted: { status: "en_route", label: "Berangkat ke lokasi" },
  en_route: { status: "in_progress", label: "Mulai pekerjaan" },
  in_progress: { status: "provider_completed", label: "Tandai selesai" },
}

const customerActions: Record<string, BookingAction> = {
  provider_completed: { status: "customer_confirmed", label: "Konfirmasi hasil" },
  customer_confirmed: { status: "closed", label: "Tutup pesanan" },
}

export function getNextBookingAction(status: string, isProvider: boolean) {
  return (isProvider ? providerActions : customerActions)[status] ?? null
}
