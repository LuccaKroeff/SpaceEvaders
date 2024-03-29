#version 330 core

// Atributos de fragmentos recebidos como entrada ("in") pelo Fragment Shader.
// Neste exemplo, este atributo foi gerado pelo rasterizador como a
// interpolação da posição global e a normal de cada vértice, definidas em
// "shader_vertex.glsl" e "main.cpp".
in vec4 position_world;
in vec4 normal;

// Posição do vértice atual no sistema de coordenadas local do modelo.
in vec4 position_model;

// Coordenadas de textura obtidas do arquivo OBJ (se existirem!)
in vec2 texcoords;

in vec4 gouraud;

// Matrizes computadas no código C++ e enviadas para a GPU
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

// Identificador que define qual objeto está sendo desenhado no momento
#define ASTEROID 0
#define SPACESHIP  1
#define SPHERE 2
#define COIN 3
#define MOON 4


uniform int object_id;

// Parâmetros da axis-aligned bounding box (AABB) do modelo
uniform vec4 bbox_min;
uniform vec4 bbox_max;

// Variáveis para acesso das imagens de textura
uniform sampler2D TextureImage0;
uniform sampler2D TextureImage1;
uniform sampler2D TextureImage2;
uniform sampler2D TextureImage3;
uniform sampler2D TextureImage4;
uniform sampler2D TextureImage5;

// O valor de saída ("out") de um Fragment Shader é a cor final do fragmento.
out vec4 color;

// Constantes
#define M_PI   3.14159265358979323846
#define M_PI_2 1.57079632679489661923

void main()
{
    // Obtemos a posição da câmera utilizando a inversa da matriz que define o
    // sistema de coordenadas da câmera.
    vec4 origin = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 camera_position = inverse(view) * origin;

    // O fragmento atual é coberto por um ponto que percente à superfície de um
    // dos objetos virtuais da cena. Este ponto, p, possui uma posição no
    // sistema de coordenadas global (World coordinates). Esta posição é obtida
    // através da interpolação, feita pelo rasterizador, da posição de cada
    // vértice.
    vec4 p = position_world;

    // Normal do fragmento atual, interpolada pelo rasterizador a partir das
    // normais de cada vértice.
    vec4 n = normalize(normal);

    // Vetor que define o sentido da fonte de luz em relação ao ponto atual.
    vec4 light_pos = normalize(vec4(-200.0,-3.0,3.0,0.0));

    vec4 l = normalize(light_pos - position_world);

    // Vetor que define o sentido da câmera em relação ao ponto atual.
    vec4 v = normalize(camera_position - p);
    vec4 r = -l+(2*n*(dot(n,l)));

    // termo h para Blinn-Phong
    vec4 h = v + light_pos;
    h = normalize(h);

    // Coordenadas de textura U e V
    float U = 0.0;
    float V = 0.0;

    // Espectro da fonte de iluminação
    vec3 I = vec3(1.0,1.0,1.0); // espectro da fonte de luz

    // Espectro da luz ambiente
    vec3 Ia = vec3(0.7,0.9,0.7); // espectro da luz ambiente

     // Parâmetros que definem as propriedades espectrais da superfície
    vec3 Kd; // Refletância difusa
    vec3 Ks; // Refletância especular
    vec3 Ka; // Refletância ambiente
    int  q;  // Expoente especular para o modelo de iluminação de Blinn-Phong

    if ( object_id == ASTEROID )
    {
        // Coordenadas de textura do plano, obtidas do arquivo OBJ.
        U = texcoords.x;
        V = texcoords.y;

        Ks = vec3(0.2f, 0.2f, 0.2f);

        q = 30;

        vec3 Kd0 = texture(TextureImage2, vec2(U,V)).rgb;
        Ka = Kd0 / 2;

        vec3 lambert = Kd0 * I * max(0,dot(n,l));
        vec3 ambient_term = Ka * Ia;
        vec3 BlinnPhong_term = Ks * I * pow(dot(n,h),q);

        color.rgb = lambert + ambient_term + BlinnPhong_term;

    }
    else if ( object_id == SPHERE )
    {
        // Coordenadas de textura do plano, obtidas do arquivo OBJ.
        U = texcoords.x;
        V = texcoords.y;

        vec4 bbox_center = (bbox_min + bbox_max) / 2.0;

        vec4 p_linha = bbox_center + (normalize(position_model - bbox_center));

        vec4 p_vetor = p_linha - bbox_center;

        float px = p_vetor.x;
        float py = p_vetor.y;
        float pz = p_vetor.z;

        U = (atan(px, pz) + M_PI)/(2*M_PI);
        V = ((asin(py/length(p_vetor)) + (M_PI_2))/M_PI);

        // Cálculo de Lambert não importa para o céu, já que ele está sempre iluminado
        vec3 Kd0 = texture(TextureImage1, vec2(U,V)).rgb;
        color.rgb = Kd0;

    }
    else if ( object_id == MOON )
    {
        // Coordenadas de textura do plano, obtidas do arquivo OBJ.
        U = texcoords.x;
        V = texcoords.y;

        vec4 bbox_center = (bbox_min + bbox_max) / 2.0;

        vec4 p_linha = bbox_center + (normalize(position_model - bbox_center));

        vec4 p_vetor = p_linha - bbox_center;

        float px = p_vetor.x;
        float py = p_vetor.y;
        float pz = p_vetor.z;

        U = (atan(px, pz) + M_PI)/(2*M_PI);
        V = ((asin(py/length(p_vetor)) + (M_PI_2))/M_PI);

        // Cálculo de Lambert não importa para o céu, já que ele está sempre iluminado
        vec3 Kd0 = texture(TextureImage5, vec2(U,V)).rgb;
        vec3 Kd1 = texture(TextureImage4, vec2(U,V)).rgb;

        Ks = vec3(0.2f, 0.2f, 0.2f);

        q = 30;

        Ka = (Kd0 + Kd1) / 4;

        vec3 lambert = (Kd0 + Kd1)/2 * I * max(0,dot(n,l));
        vec3 ambient_term = Ka * Ia;
        vec3 BlinnPhong_term = Ks * I * pow(dot(n,h),q);

        color.rgb = lambert + ambient_term + BlinnPhong_term;

    }
    else if ( object_id == SPACESHIP )
    {
        // Coordenadas de textura do plano, obtidas do arquivo OBJ.
        U = texcoords.x;
        V = texcoords.y;

        Ks = vec3(0.2f, 0.2f, 0.2f);

        vec3 Kd0 = texture(TextureImage0, vec2(U,V)).rgb;
        Ka = Kd0 * 0.5f;
        vec3 lambert = Kd0 * I * max(0,dot(n,l));
        vec3 ambient_term = Ka * Ia;


        // Avaliar equação do modelo de iluminação (para phong shading):
        color.rgb = ambient_term + lambert + Ks*I*max(0,dot(r,v));

    }
    else if ( object_id == COIN )
    {
        color = gouraud;
    }

    color.a = 1;
    color.rgb = pow(color.rgb, vec3(1.0,1.0,1.0)/2.2);
}
