/* [[file:../../../blender.org::*Ear Clip Triangulation][Ear Clip Triangulation:1]] */
package earclip_test

import "core:fmt"
import "core:mem"
import "core:strings"
import "vendor:raylib"
import earclip "../"

draw :: proc(poly : ^earclip.Polygon) {
  using raylib
  using earclip

  if len(poly.pt_list) <= 0 do return
  pt_list : [dynamic][2]f32
  defer delete(pt_list)
  for pt in poly.pt_list {
    append(&pt_list, [2]f32{pt.x, pt.y})
  }

  radius : f32 = 3
  color := WHITE
  if len(poly.ears) > 0 {
    for ei in poly.ears { // draw this triangle gray
      e := Triangle_pts{pt_list[ei.a], pt_list[ei.b], pt_list[ei.c]}
      DrawLine(cast(i32)e.a.x, cast(i32)e.a.y, cast(i32)e.b.x, cast(i32)e.b.y, GRAY) // a-b
      DrawLine(cast(i32)e.a.x, cast(i32)e.a.y, cast(i32)e.c.x, cast(i32)e.c.y, GRAY) // a-c
      DrawLine(cast(i32)e.b.x, cast(i32)e.b.y, cast(i32)e.c.x, cast(i32)e.c.y, GRAY) // b-c
    }
  } else {
    for pos, i in poly.pt_list {
      next : Vector2
      if i+1 >= len(pt_list) {
        next = Vector2{pt_list[0].x, pt_list[0].y}
      } else {
        next = Vector2{pt_list[i+1].x, pt_list[i+1].y}
      }

      DrawCircleLines(cast(i32)pos.x, cast(i32)pos.y, radius, color)
      DrawLine(cast(i32)pos.x, cast(i32)pos.y, cast(i32)next.x, cast(i32)next.y, WHITE)
    }
  }
}

main :: proc() {
  using raylib
  using earclip

  ta := mem.Tracking_Allocator{};
  mem.tracking_allocator_init(&ta, context.allocator);
  context.allocator = mem.tracking_allocator(&ta);
  
  WIDTH  :: 500
  HEIGHT :: 500
  handle_mouse1 :: proc(pt_list : ^[dynamic][3]f32) {
    using raylib
    // add new current cursor position to pt_list
    if IsMouseButtonPressed(MouseButton.LEFT) {
      gmp := GetMousePosition()
      append(pt_list, [3]f32{gmp.x, gmp.y, 1.0})
    }
  }
  handle_backspace :: proc(poly : ^earclip.Polygon) -> bool {
    using raylib
    // remove newest point
    if IsKeyPressed(KeyboardKey.BACKSPACE) && len(poly.pt_list)>0 {
      unordered_remove(&poly.pt_list, len(poly.pt_list)-1)

      earclip.triangulate(poly)
      return true
    }
    return false
  }
  handle_enter :: proc(curr_mode : ^string) {
    using raylib
    // remove newest point
    if IsKeyPressed(KeyboardKey.ENTER) {
      if curr_mode^ == "CREATION" do curr_mode^ = "MERGE"
      else if curr_mode^ == "MERGE" do curr_mode^ = "COMPLETE"
      else if curr_mode^ == "COMPLETE" do curr_mode^ = "CREATION"
    }
  }
  handle_space :: proc(pt_list : ^[dynamic][3]f32) {
    using raylib
    if IsKeyPressed(KeyboardKey.SPACE) {
      // new child TODO
    }
  }

  {
    curr_mode := "CREATION"
    poly : Polygon
    prev_len := 0

    defer delete(poly.pt_list)
    defer delete(poly.ears)
    
    InitWindow(WIDTH, HEIGHT, "Ear Clip Demo")
    SetTargetFPS(60)

    for !WindowShouldClose() {
      // Update ------------------------------
      handle_mouse1(&poly.pt_list)
      if handle_backspace(&poly) do prev_len = len(poly.pt_list)
      handle_enter(&curr_mode)
      handle_space(&poly.pt_list)
      if len(poly.pt_list) > prev_len && len(poly.pt_list) >= 3 {
        triangulate(&poly)
        prev_len = len(poly.pt_list)
      }

      // Draw   ------------------------------
      BeginDrawing()
      ClearBackground(BLACK)

      cstr := strings.clone_to_cstring(curr_mode)
      DrawText(cstr, 0, 0, 10, BLUE)
      delete(cstr)

      draw(&poly)

      EndDrawing()
    }
    CloseWindow()
  }
  
  if len(ta.allocation_map) > 0 {
    for _, v in ta.allocation_map {
      fmt.printf("Leaked %v bytes @ %v\n", v.size, v.location)
    }
  }
  if len(ta.bad_free_array) > 0 {
    fmt.println("Bad frees:")
    for v in ta.bad_free_array {
      fmt.println(v)
    }
  }
}
/* Ear Clip Triangulation:1 ends here */
