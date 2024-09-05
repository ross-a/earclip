/* [[file:../../blender.org::*Ear Clip Triangulation][Ear Clip Triangulation:2]] */
 package earclip

 import "core:slice"
 import "core:strings"
 import "core:math/linalg"

 Triangle_pts :: struct {
   a : [2]f32,
   b : [2]f32,
   c : [2]f32,
 }

 Triangle :: struct {
   a : int,
   b : int,
   c : int,
 }

 Polygon :: struct {
   pt_list : [dynamic][3]f32,
   ears    : [dynamic]Triangle,
 }

 triangulate :: proc(poly : ^Polygon) {
   pt_list := _project_onto_plane(&poly.pt_list)
   defer delete(pt_list)

   r := _going_clockwise(&pt_list)
   if r do slice.reverse(pt_list[0:])

   clear_dynamic_array(&poly.ears)

   tmp_i : [dynamic]int
   tmp_pt_list : [dynamic][2]f32
   defer delete(tmp_i)
   defer delete(tmp_pt_list)
   tpl := &tmp_pt_list
   for p,i in pt_list {
     ii := i
     if r do ii = len(pt_list)-i-1
     append(&tmp_i, ii)
     append(tpl, p)
   }

   i := 0
   times_around := 0 // TODO: fix bug/not_getting_to_3_or_below here when points "cross prev exterior lines"
   for ; len(tmp_pt_list) >= 3; {
     ii := _bound(i, tpl)

     ic := _is_convex(ii, tpl)
     if ic {
       ie := _is_ear(ii, tpl)
       if ie {
         ai := _prev(ii, tpl)
         bi := ii
         ci := _next(ii, tpl)

         append(&poly.ears, Triangle{tmp_i[ai], tmp_i[bi], tmp_i[ci]})

         ordered_remove(&tmp_i, ii)
         ordered_remove(tpl, ii)
         continue
       }
     }
     if ii == 0 do times_around += 1
     if times_around > 4 do break

     i = ii + 1
   }
   if r do slice.reverse(pt_list[0:])
 }

 // --------------------------------
 _going_clockwise :: proc(pt_list: ^[dynamic][2]f32) -> bool {
   total : f32 = 0
   for pt, i in pt_list {
     next := pt_list[_next(i, pt_list)]
     total += (next.x - pt.x) * (next.y + pt.y)
   }
   return total >= 0
 }

 _pt_in_triangle :: proc(pt: [2]f32, tri: Triangle_pts) -> bool {
   // Barycentric Technique

   // Compute vectors        
   v0 := [2]f32{tri.c.x - tri.a.x, tri.c.y - tri.a.y} // C - A
   v1 := [2]f32{tri.b.x - tri.a.x, tri.b.y - tri.a.y} // B - A
   v2 := [2]f32{pt.x - tri.a.x, pt.y - tri.a.y}       // P - A

   // Compute dot products
   dot00 := linalg.dot(v0, v0)
   dot01 := linalg.dot(v0, v1)
   dot02 := linalg.dot(v0, v2)
   dot11 := linalg.dot(v1, v1)
   dot12 := linalg.dot(v1, v2)

   // Compute barycentric coordinates
   invDenom := 1 / (dot00 * dot11 - dot01 * dot01)
   u := (dot11 * dot02 - dot01 * dot12) * invDenom
   v := (dot00 * dot12 - dot01 * dot02) * invDenom

   // Check if point is in triangle
   return (u >= 0) && (v >= 0) && (u + v < 1)
 }

 _bound :: proc(i : int, pt_list : ^[dynamic][2]f32) -> int {
   ii := i
   if ii >= len(pt_list) {
     ii = 0
   } else {
     ii = i
   }
   return ii
 }

 _next :: proc(i : int, pt_list : ^[dynamic][2]f32) -> int {
   if i+1 >= len(pt_list) {
     return 0
   } else {
     return i+1
   }
 }

 _prev :: proc(i : int, pt_list : ^[dynamic][2]f32) -> int {
   if i-1 < 0 {
     return len(pt_list)-1
   } else {
     return i-1
   }
 }

 _is_convex :: proc(i : int, pt_list : ^[dynamic][2]f32) -> bool {
   ii := _bound(i, pt_list)
   a : [2]f32 = pt_list[_prev(ii, pt_list)]
   b : [2]f32 = pt_list[ii]
   c : [2]f32 = pt_list[_next(ii, pt_list)]
   return ( ( a.x * ( c.y - b.y ) ) + ( b.x * ( a.y - c.y ) ) + ( c.x * ( b.y - a.y ) ) ) < 0
 }

 _is_ear :: proc(i : int, pt_list : ^[dynamic][2]f32) -> bool {
   ii := _bound(i, pt_list)
   next := _next(ii, pt_list)
   prev := _prev(ii, pt_list)
   nextnext := _next(_next(ii, pt_list), pt_list)
   tri := Triangle_pts{pt_list[prev], pt_list[ii], pt_list[next]}

   // check every point not part of the possible ear
   for ; nextnext != prev; nextnext = _next(nextnext, pt_list) {
     if _pt_in_triangle(pt_list[nextnext], tri) {
       return false
     }
   }
   return true;
 }

 _project_onto_plane :: proc(pts : ^[dynamic][3]f32) -> [dynamic][2]f32 {
   pts2d : [dynamic][2]f32
   if len(pts) < 3 {
     for p in pts {
       append(&pts2d, [2]f32{p.x, p.y})
     }
     return pts2d
   }
   a := pts[0]
   b := pts[1]
   c := pts[2]
   ba := b-a
   ca := c-a
   normal := linalg.normalize(linalg.cross(ba, ca))
   u := linalg.normalize(ba)
   v := linalg.normalize(linalg.cross(u, normal))
   // now project all points to 2d
   for p in pts {
     np := [2]f32{linalg.dot(p, u), linalg.dot(p, v)}
     append(&pts2d, np)
   }
   return pts2d
 }
/* Ear Clip Triangulation:2 ends here */
