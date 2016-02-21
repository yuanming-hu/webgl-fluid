//***     Globals     ***
attribute vec2 position;
uniform vec2 bufSize;
uniform int column;
uniform highp sampler2D vTexture;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
}

//*** Fragment Shader ***
void main(void)
{
    vec2 pos = gl_FragCoord.xy / bufSize;
    vec4 dat = texture2D(vTexture, pos);
    vec2 dp = vec2(0.5, 0.5) / bufSize;
    vec2 dq = vec2(0.5, -0.5) / bufSize;
    if (dat.y == 0.0) {
        vec2 sum =
               texture2D(vTexture, pos + dp).xy
             + texture2D(vTexture, pos - dp).xy
             + texture2D(vTexture, pos + dq).xy
             + texture2D(vTexture, pos - dq).xy;
        if (sum.y != 0.0) {
            sum.x /= sum.y;
            sum.y = 0.;
            dat.xy = sum;
        }
    }
    gl_FragColor = vec4(dat);
}
