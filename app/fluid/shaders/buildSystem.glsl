//***     Globals     ***
attribute vec2 position;
uniform vec2 bufSize;
uniform highp sampler2D cells;
uniform highp sampler2D uTexture;
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
    ivec2 ipos = ivec2(int(gl_FragCoord.x), int(gl_FragCoord.y));
    float Ax = 0., Ay = 0., Ad = 0., rhs = 0.;
    vec2 dx = vec2(1, 0) / bufSize, dy = vec2(0, 1) / bufSize;
    if (texture2D(cells, pos).x == 1.0) {
        /*
        if (ipos.x != 0 && texture2D(cells, pos - dx).s == 1.0) {
            Ad += 1.0;
            Ax += 2.0;
        }
        if (ipos.x != int(bufSize.x) - 1 && texture2D(cells, pos + dx).s == 1.0) {
            Ad += 1.0;
            Ax += 1.0;
        }
        if (ipos.y != 0 && texture2D(cells, pos - dy).s == 1.0) {
            Ad += 1.0;
            Ay += 2.0;
        }
        if (ipos.y != int(bufSize.y) - 1 && texture2D(cells, pos + dy).s == 1.0) {
            Ad += 1.0;
            Ay += 1.0;
        }
        */
        if (ipos.x != 0) {
            Ad += 1.0;
            Ax += 2.0;
        }
        if (ipos.x != int(bufSize.x) - 1) {
            Ad += 1.0;
            Ax += 1.0;
        }
        if (ipos.y != 0) {
            Ad += 1.0;
            Ay += 2.0;
        }
        if (ipos.y != int(bufSize.y) - 1) {
            Ad += 1.0;
            Ay += 1.0;
        }
        float u_0, u_1, v_0, v_1;
        u_0 = texture2D(uTexture, vec2((float(ipos.x) + 0.5) / (bufSize.x + 1.), pos.y)).x;
        u_1 = texture2D(uTexture, vec2((float(ipos.x) + 1.5) / (bufSize.x + 1.), pos.y)).x;
        v_0 = texture2D(vTexture, vec2(pos.x, (float(ipos.y) + 0.5) / (bufSize.y + 1.))).x;
        v_1 = texture2D(vTexture, vec2(pos.x, (float(ipos.y) + 1.5) / (bufSize.y + 1.))).x;
        rhs = -(u_1 - u_0 + v_1 - v_0);
    } else {
        Ax = Ay = rhs = 0.0;
        Ad = -1.0;
    }
    gl_FragColor = vec4(Ax, Ay, 1.0 / Ad, rhs);
    // gl_FragColor = vec4(rhs * 20., 0, 0, 1);
}
