export default function Loading() {
  return (
    <main className="container py-10 sm:py-14">
      <div className="mx-auto max-w-4xl animate-pulse">
        <div className="h-9 w-48 rounded-lg bg-muted" />
        <div className="mt-2 h-5 w-80 rounded-lg bg-muted" />
        <div className="mt-8 space-y-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="flex items-center gap-4 rounded-lg border bg-card p-5 shadow-sm">
              <div className="size-5 rounded-full bg-muted" />
              <div className="flex-1 space-y-2">
                <div className="h-4 w-3/5 rounded bg-muted" />
                <div className="h-3 w-4/5 rounded bg-muted" />
              </div>
              <div className="h-6 w-20 rounded-full bg-muted" />
            </div>
          ))}
        </div>
      </div>
    </main>
  )
}
