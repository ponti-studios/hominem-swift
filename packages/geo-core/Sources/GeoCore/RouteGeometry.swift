import Foundation

public enum RouteGeometry {
    public static func simplify(
        _ points: [GeoCoordinate],
        toleranceMeters: Double = 8,
        maxPoints: Int = 480
    ) -> [GeoCoordinate] {
        guard points.count > 2 else { return points }
        var tolerance = max(0.5, toleranceMeters)
        var result = douglasPeucker(points, toleranceDegrees: tolerance / 111_320)
        while result.count > maxPoints, tolerance < 4_000 {
            tolerance *= 2
            result = douglasPeucker(points, toleranceDegrees: tolerance / 111_320)
        }
        return result
    }

    public static func length(_ points: [GeoCoordinate]) -> Double {
        guard points.count > 1 else { return 0 }
        var total = 0.0
        var previous = points[0]
        for point in points.dropFirst() {
            total += previous.distance(to: point)
            previous = point
        }
        return total
    }

    private static func douglasPeucker(
        _ points: [GeoCoordinate],
        toleranceDegrees: Double
    ) -> [GeoCoordinate] {
        guard points.count > 2 else { return points }
        var keep = [Bool](repeating: false, count: points.count)
        keep[0] = true
        keep[points.count - 1] = true
        var stack = [(0, points.count - 1)]

        while let (start, end) = stack.popLast() {
            guard end > start + 1 else { continue }
            let a = points[start]
            let b = points[end]
            let cosLatitude = cos(a.latitude * .pi / 180)
            let dx = (b.longitude - a.longitude) * cosLatitude
            let dy = b.latitude - a.latitude
            let lengthSquared = dx * dx + dy * dy
            var farthest = 0.0
            var farthestIndex = start

            for index in (start + 1)..<end {
                let point = points[index]
                let px = (point.longitude - a.longitude) * cosLatitude
                let py = point.latitude - a.latitude
                let distanceSquared: Double
                if lengthSquared <= 1e-18 {
                    distanceSquared = px * px + py * py
                } else {
                    let projection = max(0, min(1, (px * dx + py * dy) / lengthSquared))
                    let ex = px - projection * dx
                    let ey = py - projection * dy
                    distanceSquared = ex * ex + ey * ey
                }
                if distanceSquared > farthest {
                    farthest = distanceSquared
                    farthestIndex = index
                }
            }

            if farthest > toleranceDegrees * toleranceDegrees {
                keep[farthestIndex] = true
                stack.append((start, farthestIndex))
                stack.append((farthestIndex, end))
            }
        }

        return points.indices.compactMap { keep[$0] ? points[$0] : nil }
    }
}
