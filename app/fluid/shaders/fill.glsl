//***     Globals     ***
attribute vec2 position;
uniform vec4 color;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
}

//*** Fragment Shader ***
void main(void)
{
    gl_FragColor = color;
}

