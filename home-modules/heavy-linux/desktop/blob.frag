#define r iResolution.xy

float sdf(vec4 p,mat4 m) {
    float q = 1.0;
    for(int n = 0; n < 9; n++) {
        p = (abs(p * m) - 1.0) * 1.8;
        q *= 1.8;
    }
    return (length(p) - 3.0) / q;
}

vec3 col(vec4 p,mat4 m) {
    float q = 1.0;
    vec4 h0 = vec4(1e9);
    vec4 h1 = vec4(-1e9);
    for(int n = 0; n < 9; n++) {
        p = abs(p * m) - 1.0;
        p *= 1.8;
        q *= 1.8;
        h0 = min(h0,normalize(p) * 0.5);
        h1 = max(h1,normalize(p) * 0.5);
    }
    return sqrt(normalize(abs((h1 - h0 - 0.5) * transpose(m)).xyz));
}

vec4 grad(vec4 p,mat4 m) {
    float epsilon = 0.001;
    vec4 q = vec4(
    sdf(p - vec4(1,0,0,0) * epsilon,m),
    sdf(p - vec4(0,1,0,0) * epsilon,m),
    sdf(p - vec4(0,0,1,0) * epsilon,m),
    sdf(p - vec4(0,0,0,1) * epsilon,m));
    return normalize(sdf(p,m) - q);
}

void mainImage(out vec4 c,vec2 p) {
    vec4 raypos = vec4(0,0,-12,0);
    vec4 raydir = normalize(vec4((p + p - r) / sqrt(r.x * r.y),3,0));
    
    mat4 rot = mat4(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1);
    float t0 = iTime * 0.07;
    float t1 = iTime * 0.07;
    for(int j = 0; j < 3; j++) {
        rot *= mat4(cos(t0),sin(t0),0,0,-sin(t0),cos(t0),0,0,0,0,cos(t1),sin(t1),0,0,-sin(t1),cos(t1));
        rot *= mat4(0,1,0,0,0,0,1,0,0,0,0,1,1,0,0,0);
        t0 *= 1.07145;
        t1 *= -1.1287;
    }
    
    c = vec4(0);
    
    float mdist = 1e9;
    
    for(int i = 0; i < 100; i++) {
        float dist = sdf(raypos,rot);
        raypos += raydir * dist;
        mdist = min(mdist,dist);
        if(dist < 0.003) {
            c = vec4(col(raypos,rot),1) * exp(float(i) * 0.1 * vec4(col(raypos,rot).zxy,1));
            break;
        }
        if(dist > 20.0 || i == 99) {
            c += 0.15 / sqrt(mdist) * vec4(col(raypos - grad(raypos,rot) * dist,rot).yzx,1);
            break;
        }
    }
    
    raydir = normalize(vec4(0.3,0.9,-0.4,0.7));
    
    float mang = 1e9;
    
    float tdist = 0.0;
    
    for(int i = 0; i < 50; i++) {
        float dist = sdf(raypos,rot);
        tdist += dist;
        raypos += raydir * dist;
        mang = min(mang,dist / tdist);
        if(dist < 0.00001) {
            c *= 0.7;
            break;
        }
        if(dist > 1.0) {
            break;
        }
    }
    c /= 0.7;
    c *= 1.0 - 0.8 / (mang * 4.5 + 1.0);
}
