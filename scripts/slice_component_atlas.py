#!/usr/bin/env python3
from __future__ import annotations

import json
from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
COMPONENTS_ROOT = ROOT / "images" / "trae" / "components"
MIN_PIXELS = 200
PADDING = 8

CONSTRUCTION_PREFIXES = (
    "office_arch_",
    "parede_",
    "canto_",
    "juncao_",
    "rodape_",
    "janela_",
)

CONSTRUCTION_EXACT = {
    "divisoria_baixa_bicolor_horizontal",
    "divisoria_madeira_ripada_horizontal",
    "divisoria_vidro_baixa_horizontal",
    "divisoria_vidro_canto",
    "divisoria_vidro_vertical",
    "pilar_madeira_ripado",
    "coluna_trim_clara",
    "piso_bege_carpete",
    "piso_cinza_azulejo",
    "piso_claro_quadriculado",
    "piso_grafite_quadriculado",
    "piso_madeira_clara",
    "piso_preto_tecnico",
    "modulo_banheiro_claro",
    "modulo_copa_clara",
    "parede_concreto_topo_horizontal",
    "parede_concreto_lateral_vertical_01",
    "parede_concreto_lateral_vertical_02",
    "parede_lateral_janela_vertical",
    "parede_lateral_porta_metal",
    "parede_topo_janela_longa",
    "parede_topo_porta_madeira",
    "divisoria_metal_tela_industrial",
    "divisoria_vidro_frontal_larga",
    "divisoria_vidro_lateral_estreita",
    "piso_carpete_xadrez_grafite",
    "piso_concreto_claro",
    "piso_madeira_industrial",
    "piso_metal_grafite",
    "rodape_metal_grafite_longo_01",
    "rodape_metal_grafite_longo_02",
}

CONSTRUCTION_CONTAINS = (
    "_porta_",
    "_janela_",
    "_parede_",
    "_vidro_",
    "_rodape_",
    "_coluna_",
    "_pilar_",
    "_divisoria_",
)


def detect_components(image: Image.Image, min_pixels: int = MIN_PIXELS) -> list[tuple[int, int, int, int]]:
    alpha = image.getchannel("A")
    width, height = image.size
    pixels = alpha.load()
    visited: set[tuple[int, int]] = set()
    boxes: list[tuple[int, int, int, int]] = []

    for y in range(height):
        for x in range(width):
            if pixels[x, y] == 0 or (x, y) in visited:
                continue

            queue: deque[tuple[int, int]] = deque([(x, y)])
            visited.add((x, y))
            min_x = max_x = x
            min_y = max_y = y
            area = 0

            while queue:
                cx, cy = queue.popleft()
                area += 1
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)

                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if not (0 <= nx < width and 0 <= ny < height):
                        continue
                    if pixels[nx, ny] == 0 or (nx, ny) in visited:
                        continue
                    visited.add((nx, ny))
                    queue.append((nx, ny))

            if area >= min_pixels:
                boxes.append((min_x, min_y, max_x + 1, max_y + 1))

    return sorted(boxes, key=lambda box: (box[1], box[0]))


def crop_component(image: Image.Image, box: tuple[int, int, int, int], padding: int = PADDING) -> Image.Image:
    left, top, right, bottom = box
    crop_box = (
        max(0, left - padding),
        max(0, top - padding),
        min(image.width, right + padding),
        min(image.height, bottom + padding),
    )
    cropped = image.crop(crop_box)
    bbox = cropped.getchannel("A").getbbox()
    if bbox:
        cropped = cropped.crop(bbox)
    return cropped


def component_category(name: str) -> str:
    if name in CONSTRUCTION_EXACT:
        return "construcao"
    if name.startswith(CONSTRUCTION_PREFIXES):
        return "construcao"
    if any(token in name for token in CONSTRUCTION_CONTAINS):
        return "construcao"
    return "componentes"


ATLAS_CONFIGS: list[dict[str, object]] = [
    {
        "source": COMPONENTS_ROOT / "office-directional-atlas-alpha.png",
        "theme": "office",
        "atlas": "directional",
        "items": [
            "balcao_recepcao_l_claro",
            "balcao_recepcao_reto_claro",
            "mesa_escritorio_horizontal_madeira",
            "mesa_escritorio_horizontal_divisoria_azul",
            "mesa_reuniao_horizontal_6_lugares",
            "cadeira_escritorio_azul_3_4",
            "sofa_2_lugares_azul",
            "armario_baixo_cinza",
            "planta_vaso_grande_clara",
            "planta_vaso_medio_clara",
            "planta_vaso_suporte_branco",
            "planta_vaso_pequeno_claro",
            "suculenta_vaso_claro",
            "floreira_linear_madeira",
            "divisoria_vidro_canto",
            "divisoria_vidro_vertical",
            "porta_madeira_fechada",
            "porta_metal_fechada",
            "portal_madeira_aberto",
            "janela_vertical_simples",
            "janela_horizontal_dupla",
            "janela_horizontal_longa",
            "tapete_azul_retangular",
            "tapete_bege_retangular",
            "tapete_vermelho_retangular",
            "tapete_verde_redondo",
            "reserva_directional_01",
            "reserva_directional_02",
        ],
    },
    {
        "source": COMPONENTS_ROOT / "office-materials-atlas-alpha.png",
        "theme": "office",
        "atlas": "materials",
        "items": [
            "piso_claro_quadriculado",
            "piso_grafite_quadriculado",
            "piso_cinza_azulejo",
            "piso_madeira_clara",
            "piso_bege_carpete",
            "carpete_azul_quadrado",
            "carpete_verde_quadrado",
            "carpete_bege_quadrado",
            "carpete_vermelho_quadrado",
            "tapete_redondo_bege",
            "tapete_azul_retangular_grande",
            "tapete_verde_retangular",
            "divisoria_baixa_bicolor_horizontal",
            "coluna_trim_clara",
            "divisoria_madeira_ripada_horizontal",
            "pilar_madeira_ripado",
            "divisoria_vidro_baixa_horizontal",
            "floreira_branca_linear_longa",
            "floreira_branca_linear_curta",
            "floreira_branca_linear_media",
            "floreira_branca_canto_l",
            "piso_preto_tecnico",
            "area_reuniao_azul_mesa",
            "modulo_banheiro_claro",
            "modulo_copa_clara",
        ],
    },
    {
        "source": COMPONENTS_ROOT / "office-architecture-layout-alpha.png",
        "theme": "office",
        "atlas": "architecture",
        "items": [
            "office_arch_001_parede_superior_longa",
            "office_arch_002_parede_superior_canto_direito",
            "office_arch_003_parede_superior_divisao_01",
            "office_arch_004_parede_superior_divisao_02",
            "office_arch_005_parede_superior_porta_madeira",
            "office_arch_006_parede_superior_janela_longa",
            "office_arch_007_parede_lateral_fina_esquerda",
            "office_arch_008_modulo_sala_pequeno_01",
            "office_arch_009_modulo_sala_pequeno_02",
            "office_arch_010_parede_lateral_fina_direita_01",
            "office_arch_011_parede_lateral_fina_direita_02",
            "office_arch_012_juncao_t_superior",
            "office_arch_013_canto_externo_esquerdo",
            "office_arch_014_modulo_sala_pequeno_03",
            "office_arch_015_modulo_sala_pequeno_04",
            "office_arch_016_vidro_frontal_longo",
            "office_arch_017_vidro_canto_l_esquerdo",
            "office_arch_018_vidro_frontal_t",
            "office_arch_019_modulo_canto_interno_01",
            "office_arch_020_parede_lateral_fina_direita_03",
            "office_arch_021_parede_lateral_fina_direita_04",
            "office_arch_022_modulo_canto_interno_02",
            "office_arch_023_canto_chanfrado",
            "office_arch_024_parede_baixa_horizontal_01",
            "office_arch_025_parede_baixa_horizontal_02",
            "office_arch_026_modulo_sala_pequeno_05",
            "office_arch_027_porta_madeira_topo_01",
            "office_arch_028_porta_madeira_topo_02",
            "office_arch_029_janela_pequena_quadrada_01",
            "office_arch_030_janela_horizontal_tripla_01",
            "office_arch_031_janela_vertical_estreita_01",
            "office_arch_032_janela_horizontal_dupla_01",
            "office_arch_033_janela_horizontal_longa_frontal",
            "office_arch_034_canto_externo_direito",
            "office_arch_035_parede_pequena_vertical_01",
            "office_arch_036_parede_baixa_horizontal_03",
            "office_arch_037_porta_madeira_vertical_01",
            "office_arch_038_janela_vertical_dupla_01",
            "office_arch_039_janela_vertical_dupla_02",
            "office_arch_040_janela_vertical_dupla_03",
            "office_arch_041_janela_vertical_estreita_02",
            "office_arch_042_janela_vidro_lateral_longa",
            "office_arch_043_janela_vidro_lateral_media",
            "office_arch_044_coluna_fina_01",
            "office_arch_045_coluna_fina_02",
            "office_arch_046_coluna_fina_03",
            "office_arch_047_coluna_fina_04",
            "office_arch_048_coluna_fina_05",
            "office_arch_049_divisoria_bicolor_longa",
            "office_arch_050_divisoria_bicolor_media",
            "office_arch_051_rodape_horizontal_curto_01",
            "office_arch_052_rodape_horizontal_curto_02",
            "office_arch_053_rodape_horizontal_medio_01",
            "office_arch_054_rodape_horizontal_longo_01",
            "office_arch_055_rodape_vertical_fino",
            "office_arch_056_rodape_vertical_medio",
            "office_arch_057_rodape_vertical_largo",
            "office_arch_058_rodape_horizontal_largo",
        ],
    },
    {
        "source": COMPONENTS_ROOT / "office-furniture-layout-alpha.png",
        "theme": "office",
        "atlas": "furniture",
        "items": [
            "balcao_recepcao_curvo_madeira_grande",
            "balcao_recepcao_curvo_madeira_medio",
            "cadeira_escritorio_preta_frente_01",
            "cadeira_escritorio_azul_frente_01",
            "cadeira_escritorio_verde_frente_01",
            "cadeira_escritorio_cinza_frente_01",
            "cadeira_escritorio_preta_frente_02",
            "balcao_recepcao_curvo_branco_pequeno",
            "balcao_recepcao_curvo_branco_longo",
            "balcao_recepcao_curvo_branco_l",
            "cadeira_escritorio_marrom_frente_01",
            "mesa_escritorio_l_madeira_01",
            "mesa_escritorio_l_madeira_02",
            "balcao_recepcao_curvo_branco_l_02",
            "cadeira_espera_azul_01",
            "balcao_recepcao_curvo_branco_medio",
            "cadeira_espera_preta_01",
            "cadeira_espera_azul_02",
            "cadeira_espera_preta_02",
            "cadeira_espera_verde_01",
            "cadeira_espera_azul_03",
            "mesa_redonda_madeira_01",
            "puff_azul_01",
            "puff_azul_02",
            "mesa_reuniao_vertical_6_lugares",
            "mesa_reuniao_horizontal_8_lugares",
            "sofa_preto_3_lugares",
            "sofa_azul_3_lugares",
            "sofa_verde_2_lugares",
            "poltrona_preta_01",
            "mesa_centro_madeira_01",
            "mesa_centro_vidro_01",
            "estante_madeira_01",
            "estante_madeira_02",
            "gaveteiro_arquivo_cinza_01",
            "gaveteiro_arquivo_cinza_02",
            "gaveteiro_arquivo_cinza_03",
            "armario_alto_cinza_01",
            "armario_alto_azul_01",
            "armario_alto_verde_01",
            "armario_alto_cinza_02",
            "armario_alto_bege_01",
            "monitor_duplo_largo",
            "cpu_torre_preta",
            "notebook_prata_aberto",
            "monitor_pequeno_azul",
            "notebook_preto_aberto",
            "monitor_retro_azul",
            "telefone_preto_01",
            "impressora_azul_pequena",
            "telefone_preto_02",
            "roteador_preto_wifi",
            "impressora_branca_01",
            "impressora_branca_02",
            "geladeira_branca_01",
            "bancada_copa_completa",
            "quadro_branco",
            "quadro_avisos_cortica",
            "tela_projecao",
            "quadro_paisagem",
            "quadro_abstrato",
            "diploma_moldura_01",
            "diploma_moldura_02",
            "relogio_parede",
            "porta_madeira_interna",
            "porta_vidro_interna",
            "porta_banheiro",
            "porta_automatica_vidro",
            "vaso_pequeno_claro_01",
            "vaso_pequeno_claro_02",
            "planta_arvore_vaso_marrom",
            "arbusto_redondo_vaso_preto",
            "planta_folha_longa_vaso_branco_01",
            "planta_folha_longa_vaso_branco_02",
            "luminaria_mesa_preta_01",
            "luminaria_piso_verde",
            "luminaria_piso_bege_01",
            "luminaria_piso_bege_02",
            "luminaria_mesa_preta_02",
            "tapete_azul_moldura",
            "tapete_grafite_simples",
            "tapete_verde_classico",
            "tapete_bege_classico",
            "tapete_persa_vermelho",
            "tapete_redondo_azul",
            "tapete_azul_textura",
            "tapete_cinza_textura",
            "tapete_verde_textura",
            "tapete_bege_textura",
            "decoracao_extra_01",
            "decoracao_extra_02",
            "decoracao_extra_03",
            "decoracao_extra_04",
            "decoracao_extra_05",
            "tapete_extra_01",
            "tapete_extra_02",
            "tapete_extra_03",
            "tapete_extra_04",
            "tapete_extra_05",
            "tapete_extra_06",
            "tapete_extra_07",
            "tapete_extra_08",
            "tapete_extra_09",
            "tapete_extra_10",
        ],
    },
    {
        "source": COMPONENTS_ROOT / "industrial-landscaping-layout-alpha.png",
        "theme": "industrial",
        "atlas": "landscaping",
        "items": [
            "floreira_concreto_horizontal_longa",
            "floreira_concreto_vertical_longa",
            "jardineira_metal_horizontal_longa",
            "jardineira_metal_vertical_alta",
            "jardineira_metal_vertical_estreita",
            "floreira_concreto_canto_l",
            "pedestal_concreto_estreito",
            "jardineira_metal_dupla_palmeiras",
            "vaso_concreto_redondo_medio",
            "pedestal_concreto_retangular",
            "arvore_interna_vaso_preto",
            "vaso_quadrado_concreto_folhagem",
            "vaso_espada_sao_jorge_branco",
            "vaso_monstera_preto",
            "vaso_cilindrico_branco_01",
            "vaso_cilindrico_branco_02",
            "jardineira_palmeiras_dupla_01",
            "jardineira_palmeiras_dupla_02",
            "jardineira_concreto_canto_verde",
            "floreira_concreto_horizontal_arbustos",
            "jardineira_metal_horizontal_agaves",
        ],
    },
    {
        "source": COMPONENTS_ROOT / "industrial-architecture-layout-alpha.png",
        "theme": "industrial",
        "atlas": "architecture",
        "items": [
            "parede_concreto_topo_horizontal",
            "parede_concreto_lateral_vertical_01",
            "canto_interno_concreto_01",
            "canto_interno_concreto_02",
            "juncao_t_concreto",
            "parede_concreto_lateral_vertical_02",
            "parede_topo_porta_madeira",
            "parede_lateral_porta_metal",
            "parede_topo_janela_longa",
            "parede_lateral_janela_vertical",
            "divisoria_vidro_frontal_larga",
            "divisoria_metal_tela_industrial",
            "divisoria_vidro_lateral_estreita",
            "piso_concreto_claro",
            "piso_metal_grafite",
            "piso_madeira_industrial",
            "piso_carpete_xadrez_grafite",
            "tapete_azul_reuniao",
            "tapete_geometrico_olive",
            "rodape_metal_grafite_longo_01",
            "jardineira_concreto_longa_pendente",
            "rodape_metal_grafite_longo_02",
            "jardineira_concreto_longa_suculentas",
        ],
    },
]


def validate_unique_names(configs: list[dict[str, object]]) -> None:
    seen: set[tuple[str, str]] = set()
    for config in configs:
        theme = str(config["theme"])
        for name in config["items"]:
            key = (theme, str(name))
            if key in seen:
                raise ValueError(f"Duplicated output name for theme '{theme}': {name}")
            seen.add(key)


def cleanup_theme_root(theme_dir: Path) -> None:
    for path in theme_dir.glob("*.png"):
        path.unlink()


def slice_atlas(config: dict[str, object]) -> dict[str, object]:
    source = Path(config["source"])
    theme = str(config["theme"])
    atlas_name = str(config["atlas"])
    theme_dir = COMPONENTS_ROOT / theme
    theme_dir.mkdir(parents=True, exist_ok=True)
    (theme_dir / "construcao").mkdir(parents=True, exist_ok=True)
    (theme_dir / "componentes").mkdir(parents=True, exist_ok=True)

    image = Image.open(source).convert("RGBA")
    boxes = detect_components(image)
    names = [str(item) for item in config["items"]]
    if len(boxes) != len(names):
        raise ValueError(
            f"{source.name}: detected {len(boxes)} components, but config expects {len(names)} names"
        )

    entries: list[dict[str, object]] = []
    for index, (box, name) in enumerate(zip(boxes, names), start=1):
        category = component_category(name)
        output_dir = theme_dir / category
        filename = f"{name}.png"
        target = output_dir / filename
        cropped = crop_component(image, box)
        cropped.save(target)
        entries.append(
            {
                "index": index,
                "name": name,
                "category": category,
                "file": f"{theme}/{category}/{filename}",
                "atlas": atlas_name,
                "source": source.name,
                "bbox": {"left": box[0], "top": box[1], "right": box[2], "bottom": box[3]},
                "size": {"w": cropped.width, "h": cropped.height},
            }
        )

    return {
        "theme": theme,
        "atlas": atlas_name,
        "source": source.name,
        "count": len(entries),
        "entries": entries,
    }


def write_theme_manifest(theme: str, sections: list[dict[str, object]]) -> None:
    target = COMPONENTS_ROOT / theme / "manifest.json"
    target.write_text(
        json.dumps(
            {
                "version": 1,
                "theme": theme,
                "generatedFrom": "scripts/slice_component_atlas.py",
                "folders": {
                    "construcao": f"{theme}/construcao",
                    "componentes": f"{theme}/componentes",
                },
                "sections": sections,
            },
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )


def main() -> None:
    validate_unique_names(ATLAS_CONFIGS)
    grouped: dict[str, list[dict[str, object]]] = {"office": [], "industrial": []}
    cleanup_theme_root(COMPONENTS_ROOT / "office")
    cleanup_theme_root(COMPONENTS_ROOT / "industrial")
    for config in ATLAS_CONFIGS:
        result = slice_atlas(config)
        grouped[result["theme"]].append(result)
        print(f"Sliced {result['source']} -> {result['count']} components")

    for theme, sections in grouped.items():
        write_theme_manifest(theme, sections)
        print(f"Wrote manifest: {COMPONENTS_ROOT / theme / 'manifest.json'}")


if __name__ == "__main__":
    main()
