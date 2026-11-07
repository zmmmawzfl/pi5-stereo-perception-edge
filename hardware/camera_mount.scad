// 双目 IMX219 基线支架（参数化）
// 单位：mm。默认按常见 25x24mm 摄像头板、21x12.5mm 孔距设计。
// 打印前务必用卡尺量你手头的板：孔距、孔径、镜头中心偏移。
// 基线 = 两个镜头中心距离，不是两块 PCB 边缘距离。

/* [Baseline] */
baseline = 80;          // 镜头中心距；推荐 80（近距操作/室内）

/* [Camera board] */
board_w = 25;           // 板宽 X
board_h = 24;           // 板高 Z
board_t = 1.6;          // 板厚 Y
hole_dx = 21;           // 左右安装孔距
hole_dy = 12.5;         // 上下安装孔距
hole_d = 2.2;           // 安装孔直径
lens_dx = 0;            // 镜头中心相对板中心的 X 偏移
lens_dz = 0;            // 镜头中心相对板中心的 Z 偏移

/* [Mount] */
plate_w = 34;           // 立板宽
plate_h = 38;           // 立板高
plate_t = 5;            // 立板厚
base_t = 8;             // 底板厚（含 1/4-20 螺母槽）
base_depth = 38;        // 底板深
base_margin = 8;        // 底板两端余量
lens_z = 26;            // 镜头中心离底面高度
slot_w = 14;            // 排线槽宽
slot_h = 8;             // 排线槽高
tripod_d = 6.4;         // 1/4-20 螺钉过孔
tripod_trap_d = 13;     // 1/4-20 六角螺母对角间隙（按你的螺母实测）
tripod_trap_h = 5.6;    // 螺母槽深；底板 8mm，留 2.4mm 顶

$fn = 32;

// 立板中心 = PCB 中心；镜头中心相对 PCB 中心偏移 lens_dx/lens_dz。
plate_spacing = baseline - 2 * lens_dx;
base_len = plate_spacing + plate_w + 2 * base_margin;
plate_z0 = base_t - 2;  // 与底板重叠 2mm，保证 union 后不脱开
plate_z1 = plate_z0 + plate_h;
board_cz = lens_z - lens_dz;

module screw_holes(cx) {
    for (sx = [-1, 1], sz = [-1, 1]) {
        translate([cx + sx * hole_dx / 2, -plate_t - 2, board_cz + sz * hole_dy / 2])
            rotate([-90, 0, 0])
                cylinder(h = plate_t + 3, d = hole_d, center = false);
    }
}

module plate(cx) {
    difference() {
        translate([cx - plate_w / 2, -plate_t, plate_z0])
            cube([plate_w, plate_t, plate_h]);

        // 四颗 M2 螺丝：从板前穿过 PCB 拧进立板
        screw_holes(cx);

        // 底部排线槽：从底板上面一直开到板底边
        translate([cx - slot_w / 2, -plate_t - 2, plate_z0 + 2])
            cube([slot_w, plate_t + 4, slot_h]);

        // 顶部减重/减料槽（不影响孔位）
        translate([cx - 8, -plate_t - 1, plate_z1 - 8])
            cube([16, plate_t + 2, 5]);
    }
}

module gusset(cx, side) {
    // 三角筋：底板 -> 立板背面。放在两侧，给中间排线槽让路。
    gx = cx + side * (plate_w / 2 - 5);
    hull() {
        translate([gx - 2.5, -plate_t, plate_z0]) cube([5, plate_t, 1]);
        translate([gx - 2.5, -plate_t - 14, plate_z0]) cube([5, 1, 1]);
        translate([gx - 2.5, -plate_t, lens_z]) cube([5, 1, 1]);
    }
}

module body() {
    union() {
        // 底板
        translate([-base_len / 2, -base_depth + 8, 0])
            cube([base_len, base_depth, base_t]);

        // 两片立板
        plate(-plate_spacing / 2);
        plate( plate_spacing / 2);

        // 加强筋
        for (sx = [-1, 1]) {
            gusset(-plate_spacing / 2, sx);
            gusset( plate_spacing / 2, sx);
        }

    }
}

difference() {
    body();

    // 底板四角留安装孔（可选：扎带/螺丝固定到平台）
    for (sx = [-1, 1]) {
        translate([sx * (base_len / 2 - 6), 4, -0.1])
            cylinder(h = base_t + 0.2, d = 3.4, center = false);
    }

    // 1/4-20 三脚架：底部平贴床面，螺母从底部嵌入
    translate([0, 0, -0.1])
        cylinder(h = base_t + 0.2, d = tripod_d, center = false);
    translate([0, 0, -0.1])
        cylinder(h = tripod_trap_h, d = tripod_trap_d, center = false, $fn = 6);

    // 给三脚架螺钉头留一点底部沉孔
    translate([0, 0, -0.1])
        cylinder(h = 1.2, d = 12.0, center = false);
}

echo(str("baseline = ", baseline, " mm, plate spacing = ", plate_spacing, " mm"));
// 打印方向：底板贴床，立板朝上；孔轴水平，建议 0.2mm 层高、4 圈壁、40% 填充。
// 材料：PETG 优于 PLA（抗蠕变、刚性更好）；不要用柔性材料。
