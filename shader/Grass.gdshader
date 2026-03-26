shader_type spatial;
render_mode blend_mix, cull_disabled;

// 基础纹理
uniform sampler2D albedo_texture : source_color;
// 圆润程度 (0 = 尖锐, 1 = 非常圆润)
uniform float roundness : hint_range(0.0, 1.0) = 0.6;
// 边缘收缩强度
uniform float shrink_strength : hint_range(0.0, 0.3) = 0.15;
// 是否同时调整法线
uniform bool adjust_normals = true;

// 顶点着色器 - 关键部分！
void vertex() {
    // --- 1. 识别顶点属于哪个三角形面 ---
    // 对于交叉草模型，通常有两个垂直的平面
    // 我们可以通过法线方向来判断：一个面法线主要朝+X，另一个朝+Z
    
    // 获取模型空间的法线
    vec3 normal_model = NORMAL;
    
    // 判断当前顶点属于哪个面
    bool is_x_face = abs(normal_model.x) > abs(normal_model.z);
    
    // --- 2. 基于UV计算边缘因子 ---
    // 对于草模型，UV通常是这样分布的：
    // - U从根部(0)到尖部(1)
    // - V从叶片一侧(0)到另一侧(1)
    
    // 计算到叶片边缘的距离 (V方向)
    float dist_to_v_edge = min(UV.y, 1.0 - UV.y);
    // 计算到叶片尖端的距离 (U方向)
    float dist_to_tip = 1.0 - UV.x;
    
    // 综合边缘因子：尖端和两侧都要圆润
    float edge_factor = 1.0 - smoothstep(0.0, 0.4, min(dist_to_v_edge, dist_to_tip * 0.5));
    
    // --- 3. 计算位移方向 ---
    vec3 move_dir = vec3(0.0);
    
    if (is_x_face) {
        // 对于朝向X轴的面，主要在X方向收缩
        // 同时根据UV位置让边缘向中心靠拢
        float side_factor = (UV.y - 0.5) * 2.0;  // -1 到 1
        move_dir.x = -normal_model.x * 0.7;  // 向内收缩
        move_dir.z = side_factor * 0.3;       // 向叶片中心收缩
    } else {
        // 对于朝向Z轴的面
        float side_factor = (UV.y - 0.5) * 2.0;
        move_dir.z = -normal_model.z * 0.7;
        move_dir.x = side_factor * 0.3;
    }
    
    // 添加向叶片中心收缩的分量
    move_dir.y = -0.2;  // 轻微向下收缩，让叶片更聚拢
    
    // 归一化位移方向
    move_dir = normalize(move_dir);
    
    // --- 4. 应用位移 ---
    float displacement = edge_factor * roundness * shrink_strength;
    VERTEX += move_dir * displacement;
    
    // --- 5. 调整法线以配合几何变化 ---
    if (adjust_normals) {
        // 让边缘的法线向外偏，增强圆润感
        vec3 new_normal = NORMAL;
        
        if (is_x_face) {
            new_normal.x *= 1.0 - edge_factor * 0.3;
            new_normal.z += (UV.y - 0.5) * edge_factor * 0.5;
        } else {
            new_normal.z *= 1.0 - edge_factor * 0.3;
            new_normal.x += (UV.y - 0.5) * edge_factor * 0.5;
        }
        
        // 让尖端稍微上翘
        new_normal.y += UV.x * edge_factor * 0.2;
        
        NORMAL = normalize(new_normal);
    }
}

// 片段着色器 - 处理颜色和表面细节
void fragment() {
    vec4 albedo_tex = texture(albedo_texture, UV);
    ALBEDO = albedo_tex.rgb;
    ALPHA = albedo_tex.a;
    
    // 计算边缘因子用于表面属性调整
    float dist_to_v_edge = min(UV.y, 1.0 - UV.y);
    float dist_to_tip = 1.0 - UV.x;
    float edge = 1.0 - smoothstep(0.0, 0.3, min(dist_to_v_edge, dist_to_tip));
    
    // 让边缘更粗糙，中间更光滑，增强立体感
    ROUGHNESS = mix(0.3, 0.7, edge);
    
    // 添加轻微的边缘光效果
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), 2.0);
    EMISSION = ALBEDO * fresnel * 0.1 * (1.0 - edge);
}