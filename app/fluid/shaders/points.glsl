//***     Globals     ***
attribute float id;
uniform highp sampler2D texture;
uniform vec2 bufSize;
varying vec3 color;

//***  Vertex Shader  ***
void main(void)
{
    float hid = id + 0.5;
    float width = bufSize.x;
    float x = floor(mod(hid, width));
    float y = floor(hid / width);
    vec4 data = texture2D(texture, vec2(x, y) / bufSize);
    vec2 pos = data.xy * 2.0 - vec2(1);
    gl_Position = vec4(pos, 0.0, 1.0);
    gl_PointSize = 2.0;
    //  color = vec3(atan(data.zw) / acos(-1.) + 0.5, 1);
    color = vec3(0.0, 0.3, 0.95);
}

//*** Fragment Shader ***
void main(void)
{
    float alpha = max(0.0, 1.0 - dot(gl_PointCoord - vec2(0.5), gl_PointCoord - vec2(0.5)) * 5.);
    gl_FragColor = vec4(color, alpha);
}