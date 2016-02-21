//***     Globals     ***
attribute vec2 position;
uniform highp sampler2D texture;
uniform vec2 bufSize;
varying vec2 textureCoord;

//***  Vertex Shader  ***
void main(void)
{
    gl_Position = vec4(position, 0.0, 1.0);
    textureCoord = position * 0.5 + vec2(0.5);
}

//*** Fragment Shader ***
void main(void)
{
    const float deltaT = 0.002;
    vec4 data = texture2D(texture, textureCoord);
    vec2 pos = data.xy;
    vec2 vel = data.zw;
    // vec2 f = vec2(-pos.y, pos.x);
    // vec2 f = fract(vec2(sin(dot(pos, vec2(34., 42.))), sin(dot(pos, vec2(75., 21.))))) * 2. - 1.;
    vec2 f = vec2(pos.y * pos.y, -sin(pos.x));
    vec2 newVel = vel + deltaT * f;
    vec2 newPos = pos + deltaT * newVel;
    newPos = mod(newPos + vec2(1.), 2.) - vec2(1.);
    newVel = newVel * 0.996;
    gl_FragColor = vec4(newPos, newVel);
}

