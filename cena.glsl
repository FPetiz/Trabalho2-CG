#version 330 core

// Definição de texturas
#iChannel0 "file://./Texturas/Grass/Grass004_1K-JPG_Color.jpg"
#iChannel1 "file://./Texturas/Metal/Metal014_1K-JPG_Color.jpg"
#iChannel2 "file://./Texturas/Leather/Leather030.png"

// Controla o tempo de animação, tem um canal para cada textura
uniform float     iChannelTime[4];       // Tempo da unidade de canal
// uniform vec2 iResolution;  // Resolução da tela

#define MAX_STEPS 100
#define MAX_DIST 40.
#define SURF_DIST .005

// Definição de materiais no shader
const int mat_support = 1;
const int mat_bar = 2;
const int mat_ball = 3;
const int mat_line = 4;

// Rugosidade dos materiais
const float GRASS_ROUGHNESS = 0.9;
const float METAL_ROUGHNESS = 0.2;
const float LEATHER_ROUGHNESS = 0.7;
const float LINE_ROUGHNESS = 0.8;

// Funções para geometria

/*  ============================================
    Rot
    --------------------------------------------
    Cria matriz de rotação (em torno do eixo y).
    ============================================    */
mat2 Rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

/*  ============================================
    SDFbox
    --------------------------------------------
    Calcula a distância até uma caixa 3D. Usada 
    em GetDist para determinar se um ponto está 
    dentro ou fora do campo (support).
    ============================================    */
float SDFbox(vec3 pos, vec3 dim) {
    vec3 p = abs(pos) - dim;
    return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);
}

/*  ============================================
    SDFsphere
    --------------------------------------------
    Calcula a distância até uma esfera. Usada em 
    SDFBall para detectar a posição da bola.
    ============================================    */
float SDFsphere(vec3 pos, float r) {
    return length(pos) - r;
}

/*  ============================================
    SDF2box
    --------------------------------------------
    Calcula a distância até uma caixa 2D. Usada em
    GetDist para desenhar as goleiras na posição correta.
    ============================================    */
float SDF2box(vec2 pos, vec2 dim) {
    vec2 p = abs(pos) - dim;
    return length(max(p, 0.)) + min(max(p.x, p.y), 0.);
}

/*  ============================================
    SDFball
    --------------------------------------------
    Calcula a distância até uma esfera. Usada em
    GetDist para desenhar a ola na posuição correta.
    ============================================    */
vec2 SDFball(vec3 pos, float a) {
    pos.y -= 1.8;
    pos.yx *= Rot(a);
    pos.y += 1.8;
    float sphereDist = SDFsphere(pos - vec3(0, .23, 0), .1);
    vec3 sim = pos;
    sim.z = abs(sim.z);
    float dist = sphereDist;
    return vec2(dist, sphereDist == dist ? mat_ball : mat_line);
}

/*  ============================================
    SDFfieldLine
    --------------------------------------------
    Calcula a distância até as linhas do campo. 
    Usada em GetDist para calcular onde cada linha 
    deve ser desenhada.
    ============================================    */
float SDFfieldLine(vec3 p, float lineWidth) {
    // Move point to support surface
    vec3 fieldPos = p;
    fieldPos.y -= 0.1; // Move to the top of the support
    
    //vec3 supportSize = vec3(1.5, .1, 3.0); // Defina o tamanho do suporte

    // Field dimensions (based on the support size)
    float fieldLength = 3.0 - 0.1; // z-axis
    float fieldWidth = 1.5 - 0.1;  // x-axis
        
    // Center field line
    float centerLine = abs(fieldPos.z) - lineWidth;
    
    // Outer boundary
    float outerBoundaryX = abs(abs(fieldPos.x) - fieldWidth) - lineWidth;
    float outerBoundaryZ = abs(abs(fieldPos.z) - fieldLength) - lineWidth;
    float outerBoundary = min(outerBoundaryX, outerBoundaryZ);
    
    // Goal areas
    float goalAreaWidth = 0.4;
    float goalAreaLength = 0.5;
    float goalAreaX = abs(abs(fieldPos.x) - goalAreaWidth) - lineWidth;
    float goalAreaZPos = abs(fieldPos.z - (fieldLength - goalAreaLength)) - lineWidth;
    float goalAreaZNeg = abs(fieldPos.z - (goalAreaLength - fieldLength)) - lineWidth;
    float goalAreaPos = max(goalAreaX, goalAreaZPos);
    float goalAreaNeg = max(goalAreaX, goalAreaZNeg);
    float goalAreas = min(goalAreaPos, goalAreaNeg);
    
    // Center circle
    float centerCircle = abs(length(vec2(fieldPos.x, fieldPos.z)) - 0.3) - lineWidth;
    
    // Combine all lines
    float fieldLines = min(min(centerLine, outerBoundary), min(goalAreas, centerCircle));
    
    // Only draw lines on the surface of the support
    return max(fieldLines, abs(fieldPos.y) - 0.01);
}

/*  ============================================
    GetDist
    --------------------------------------------
    Calcula a menor distância até a superfície mais 
    próxima de um ponto no espaço. Usada em RayMarch 
    para calcular a superfície que o raio atinge e em 
    GetNormal para calcular a direção perpendicular 
    à superfície, para os efeitos de luz e sombra.
    ============================================   */
vec2 GetDist(vec3 pos) {
    vec2 ball1 = SDFball(pos, 0.05);
    
    float support = SDFbox(pos - vec3(0, 0, 0), vec3(1.5, .1, 3.0) - 0.05) - 0.05;
    support = max(support, -pos.y);
    
    float bar = length(vec2(SDF2box(pos.yx, vec2(1.0, 0.6)), abs(pos.z) - 2.5)) - 0.05;
    bar = max(bar, -pos.y);
    
    vec2 ball = ball1;
    float fieldLines = SDFfieldLine(pos, 0.02);
    
    // Compare all distances to find the minimum
    float dist = min(min(min(support, bar), ball.x), fieldLines);
    int mat = 0;
    
    if (dist == support) mat = mat_support;
    else if (dist == bar) mat = mat_bar;
    else if (dist == ball.x) mat = int(ball.y);
    else if (dist == fieldLines) mat = mat_line;
    
    return vec2(dist, mat);
}

/*  ============================================
    RayMarch
    --------------------------------------------
    Calcula a distância que o raio percorre até 
    encontrar uma superfície. Usada em Render
    ============================================   */
vec2 RayMarch(vec3 ro, vec3 rd) {
    float dO = 0.;
    vec2 dS = vec2(0.);
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 pos = ro + rd * dO;
        dS = GetDist(pos);
        dO += dS.x;
        if(dO > MAX_DIST || dS.x < SURF_DIST) break;
    }
    return vec2(dO, dS.y);
}

/*  ============================================
    GetNormal
    --------------------------------------------
    Calcula o vetor normal (direção perpendicular) 
    de uma superfície 3D no ponto onde o raio tocou.
    Usada em Render
    ============================================   */
vec3 GetNormal(vec3 pos) {
    float dist = GetDist(pos).x;
    vec2 eps = vec2(.01, 0);
    vec3 norm = dist - vec3(
        GetDist(pos - eps.xyy).x,
        GetDist(pos - eps.yxy).x,
        GetDist(pos - eps.yyx).x);
    return normalize(norm);
}

/*  ============================================
    GetRayDir
    --------------------------------------------
    Calcula direção de um raio que sai de um ponto 3D
    para um ponto 2D.
    Usada em mainImage
    ============================================   */
vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l - p),
         r = normalize(cross(vec3(0, 1, 0), f)),
         u = cross(f, r),
         c = f * z,
         i = c + uv.x * r + uv.y * u,
         d = normalize(i);
    return d;
}

/*  ============================================
    getSunPosition
    --------------------------------------------
    Calcula a posição do sol na cena, criando sua
    trajetória ao modificar o ângulo com base no tempo.
    Usada em Render
    ============================================   */
vec3 getSunPosition(float time) {
    float angle = time * 0.1;
    float height = sin(angle) * 5.0;
    float x = cos(angle) * 20.0;
    float z = sin(angle) * 20.0;
    return vec3(x, height, 1.0);
}

/*  ============================================
    getSunColor
    --------------------------------------------
    Calcula a cor do sol com base em sua posição.
    Usada em getSunAtmosphere e Render.
    ============================================   */
vec3 getSunColor(vec3 sunPos) {
    float sunHeight = normalize(sunPos).y;
    return mix(vec3(1.0, 0.5, 0.2), vec3(1.0, 0.9, 0.7), smoothstep(0.0, 0.5, sunHeight));  // para suavizar a transição
}

/*  ============================================
    getSunAtmosphere
    --------------------------------------------
    Calcula o brilho ao redor do sol. Usada em Render.
    ============================================   */
vec3 getSunAtmosphere(vec3 rd, vec3 sunDir) {
    float sunDot = max(dot(rd, sunDir), 0.0);
    float sunIntensity = pow(sunDot, 256.0) * 2.0;
    float sunGlow = pow(sunDot, 8.0) * 0.2;
    vec3 sunColor = getSunColor(sunDir);
    return sunColor * (sunIntensity + sunGlow);
}

/*  ============================================
    triplanarMapping
    --------------------------------------------
    Pojeta a textura em três planos diferentes.
    Usada em Render.
    ============================================   */
vec3 triplanarMapping(sampler2D tex, vec3 p, vec3 normal, float scale) {
    vec2 uvX = p.zy * scale;
    vec2 uvY = p.xz * scale;
    vec2 uvZ = p.xy * scale;
    
    vec3 colX = texture(tex, uvX).rgb;
    vec3 colY = texture(tex, uvY).rgb;
    vec3 colZ = texture(tex, uvZ).rgb;
    
    vec3 blending = abs(normal);
    blending = normalize(max(blending, 0.00001));
    
    return colX * blending.x + colY * blending.y + colZ * blending.z;
}

/*  ============================================
    microfacetBRDF
    --------------------------------------------
    Calcula o reflexo da luz em superfícies rugosas.
    Usada em Render
    ============================================   */
float microfacetBRDF(vec3 normal, vec3 viewDir, vec3 lightDir, float roughness) {
    vec3 h = normalize(viewDir + lightDir);
    float NdotH = max(dot(normal, h), 0.0);
    float NdotL = max(dot(normal, lightDir), 0.0);
    float NdotV = max(dot(normal, viewDir), 0.0);
    
    // D term (Beckmann distribution)
    float alpha = roughness * roughness;
    float NdotH2 = NdotH * NdotH;
    float D = exp((NdotH2 - 1.0) / (alpha * NdotH2)) / (3.14159265 * alpha * NdotH2 * NdotH2);
    
    // Simplified G and F terms
    float G = min(1.0, min(2.0 * NdotH * NdotV / dot(h, viewDir), 2.0 * NdotH * NdotL / dot(h, lightDir)));
    float F = 0.04 + 0.96 * pow(1.0 - dot(h, viewDir), 5.0);
    
    return D * G * F / (4.0 * NdotV * NdotL);
}

/*  ============================================
    calcShadow
    --------------------------------------------
    Calcula se um ponto está na sombra de outro
    objeto para determinar o comportamento da sombra.
    Usada em Render
    ============================================   */
float calcShadow(vec3 ro, vec3 rd, float mint, float maxt) {
    float res = 1.0;    // sem sombra
    float t = mint;
    for(int i = 0; i < 16; i++) {
        float h = GetDist(ro + rd * t).x;
        if(h < 0.001) return 0.0;   // sombra total
        res = min(res, 8.0 * h / t);    // sombra suave
        t += h;
        if(t > maxt) break;
    }
    return res;
}

/*  ============================================
    Render
    --------------------------------------------
    Executa o ray marching para encontrar a interseção
    do raio da câmera com a cena e calcula a iluminação 
    e os materiais do objeto atingido. Cria um efeitos de 
    iluminação, sombra e reflexão. Usada em mainImage.
    ============================================   */
vec3 Render(inout vec3 ro, inout vec3 rd, inout vec3 ref, bool last) {
    // Inicializa a posição e direção do sol e a cor do céu
    vec3 sunPos = getSunPosition(iTime);
    vec3 sunDir = normalize(sunPos);
    vec3 sunColor = getSunColor(sunPos);

    float horizonFactor = smoothstep(-0.2, 0.5, rd.y);
    vec3 skyColor = mix(vec3(1.0, 0.5, 0.2), vec3(0.1, 0.2, 0.4), horizonFactor);
    vec3 col = skyColor;
    
    col += getSunAtmosphere(rd, sunDir);

    // Realiza o Ray Marching para determinar se o raio colide com um objeto
    vec2 d = RayMarch(ro, rd);

    if (d.x < MAX_DIST) {
        // Obtém a posição de impacto, a normal da superfície e reflete o raio
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);
        
        // Define propriedades do material com base no tipo de objeto atingido
        float roughness = 0.5;
        float ambientStrength = 0.3;
        float directionalStrength = 1.0;
        float specularStrength = 0.5;
        vec3 albedo = vec3(1.0);
        
        if (d.y == float(mat_support)) {
            roughness = GRASS_ROUGHNESS;
            ambientStrength = 0.4;
            directionalStrength = 0.8;
            specularStrength = 0.1;
            albedo = triplanarMapping(iChannel0, p, n, 0.5);
        } else if (d.y == float(mat_bar)) {
            roughness = METAL_ROUGHNESS;
            ambientStrength = 0.2;
            directionalStrength = 1.2;
            specularStrength = 1.0;
            albedo = triplanarMapping(iChannel1, p, n, 0.5);
        } else if (d.y == float(mat_ball)) {
            roughness = LEATHER_ROUGHNESS;
            ambientStrength = 0.3;
            directionalStrength = 1.0;
            specularStrength = 0.3;
            
            vec3 localPos = normalize(p - vec3(0, 0.23, 0));
            float u = 0.5 + atan(localPos.z, localPos.x) / (2.0 * 3.14159265);
            float v = 0.5 - asin(localPos.y) / 3.14159265;
            
            albedo = texture(iChannel2, vec2(u, v)).rgb;
        } else if (d.y == float(mat_line)) {
            roughness = LINE_ROUGHNESS;
            ambientStrength = 0.4;
            directionalStrength = 1.0;
            specularStrength = 0.1;
            albedo = vec3(1.0);
        }
        
        // Calcula sombras, luz ambiente, luz difusa e especular
        float shadow = calcShadow(p + n * 0.01, sunDir, 0.1, 10.0);
        
        vec3 ambient = vec3(0.2, 0.15, 0.1) * ambientStrength;
        
        float diff = max(dot(n, sunDir), 0.0);
        vec3 diffuse = sunColor * diff * directionalStrength * shadow;
        
        vec3 viewDir = normalize(ro - p);
        float spec = microfacetBRDF(n, viewDir, sunDir, roughness);
        vec3 specular = sunColor * spec * specularStrength * shadow;
        
        float skyLight = 0.5 + 0.5 * n.y;
        vec3 skyDiffuse = skyColor * skyLight * 0.2;
        
        float groundLight = max(0.0, n.y) * 0.2;
        vec3 groundDiffuse = vec3(0.3, 0.25, 0.2) * groundLight;
        
        vec3 lighting = ambient + diffuse + skyDiffuse + groundDiffuse;
        
        // Calcula a cor final com base na iluminação e no material
        col = albedo * lighting + specular;
        
        if (roughness < 0.5) {
            // Ajusta o raio para permitir múltiplas reflexões
            float reflectionStrength = (1.0 - roughness * 2.0) * 0.5;
            ref *= vec3(reflectionStrength);
            ro = p + n * SURF_DIST * 3.0;
            rd = r;
        } else {
            ref = vec3(0.0); // Sem reflexão
        }
    } else {
        ref = vec3(0.0);
    }

    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Corrige a resolução
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Definir m com base na posição do mouse
    vec2 m = iMouse.xy / iResolution.xy;
    if (iMouse.z <= 0.0) { // Default camera angle if mouse is not being used
        m = vec2(0.5, 0.2);
    }

    // Inicializa a posição da câmera e o vetor de direção
    vec3 ro = vec3(0, 3, -7);

    ro.yz *= Rot(-m.y * 3.14 + 1.);
    ro.xz = ro.xz * Rot(-m.x * 6.2831);

    vec3 rd = GetRayDir(uv, ro, vec3(0, 0.75, 0), 1.6);
    vec3 ref = vec3(1.);

    // Chama a função Render
    vec3 col = Render(ro, rd, ref, false);

    // Número de reflexões
    int NB_BOUNCE = 1; // Reduced to 1 for better performance and fewer artifacts

    // Reflexão adicional
    for (int i = 0; i < NB_BOUNCE; i++) {
        vec3 ref1 = ref;
        col += ref1 * Render(ro, rd, ref, i + 1 == NB_BOUNCE);
    }

    // Apply tone mapping for better dynamic range
    col = col / (col + vec3(1.0)); // Reinhard tone mapping
    
    // Aplica uma transformação de cor
    col = pow(col, vec3(0.4545));
    
    // Add slight vignette effect
    vec2 center = fragCoord / iResolution.xy - 0.5;
    float vignette = 1.0 - dot(center, center) * 0.5;
    col *= vignette;

    fragColor = vec4(col, 1.0); // Atribui a cor final ao fragmento
}