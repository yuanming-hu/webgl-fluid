//***     Globals     ***
attribute vec2 position;
uniform vec2 bufSize;
uniform vec2 offset;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
}

//*** Fragment Shader ***
void main(void)
{
    vec2 pos = 0.5 * gl_FragCoord.xy / bufSize + offset;
    gl_FragColor = vec4(pos, 0, 0);
}
