#version 410
precision mediump float;
uniform sampler2D u_image;
uniform float u_alpha;
in vec2 v_tex_coord;
in vec4 v_color;
out vec4 o_color;
void main()
{
  // get the color from the attributes
  vec4 input_color = v_color;
  // set its alpha color if necessary
  if (input_color.w == 1.0)
  {
    input_color.w = u_alpha;
  }
  // get the color from the texture
  o_color = texture(u_image, v_tex_coord);
  // if it's black, make it a transparent pixel
  if (o_color.rgb == vec3(0.0, 0.0, 0.0))
  {
    o_color = vec4(0.0, 0.0, 0.0, 0.0);
  }
  // otherwise, use the input color
  else
  {
    o_color = input_color;
  }
  // the size of one pixel
  vec2 one_pixel = vec2(1) / vec2(textureSize(u_image, 0));
  // left
  vec4 left_color = texture(u_image, v_tex_coord + vec2(one_pixel.x, 0.0));
  if (left_color.rgb == vec3(0.0, 0.0, 0.0))
  {
    left_color = vec4(0.0, 0.0, 0.0, 0.0);
  }
  else
  {
    left_color = input_color;
  }
  // right
  vec4 right_color = texture(u_image, v_tex_coord + vec2(0 - one_pixel.x, 0.0));
  if (right_color.rgb == vec3(0.0, 0.0, 0.0))
  {
    right_color = vec4(0.0, 0.0, 0.0, 0.0);
  }
  else
  {
    right_color = input_color;
  }
  // top
  vec4 top_color = texture(u_image, v_tex_coord + vec2(0.0, one_pixel.y));
  if (top_color.rgb == vec3(0.0, 0.0, 0.0))
  {
    top_color = vec4(0.0, 0.0, 0.0, 0.0);
  }
  else
  {
    top_color = input_color;
  }
  // bottom
  vec4 bottom_color = texture(u_image, v_tex_coord + vec2(0.0, 0 - one_pixel.y));
  if (bottom_color.rgb == vec3(0.0, 0.0, 0.0))
  {
    bottom_color = vec4(0.0, 0.0, 0.0, 0.0);
  }
  else
  {
    bottom_color = input_color;
  }
  // average
  o_color = (o_color + left_color + right_color + top_color + bottom_color) / 5.0;
  // discard transparent pixels
  if (o_color.w == 0.0)
  {
    discard;
  }
}
