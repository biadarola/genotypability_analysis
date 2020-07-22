#!/bin/bash

OMNI="1000G_omni2.5.hg38.vcf";
AXIOM="Axiom_Exome_Plus.genotypes.all_populations.poly.hg38.vcf";
dict="Homo_sapiens_assembly38.dict";
FASTA="Homo_sapiens_assembly38.fasta";
MILLS="Mills_and_1000G_gold_standard.indels.hg38.vcf";
DBSNP="resources_broad_hg38_v0_Homo_sapiens_assembly38.dbsnp138.vcf";
gnomAD="gnomAD_3/gnomad.genomes.r3.0.sites.vcf.gz";
PHASE1="1000G_phase1.snps.high_confidence.hg38.vcf"

#REFSEQ
RefSeq_bed="RefSeq/refseq_hg38_CDS.merged.symbol.IGV_noHAPLO.bed";
RefSeq_interval="RefSeq/refseq_hg38_CDS.merged.symbol.IGV_noHAPLO.bed.interval";

#KIT BED

MED_bed="kit/SeqCap_EZ_MedExome/MedExome_hg38_capture_targets.merged.bed";
MED_interval="kit/SeqCap_EZ_MedExome/MedExome_hg38_capture_targets.merged.bed.interval";
AG_V6_bed="kit/SureSelect_Human_All_Exon_V6_r2/S07604514_Regions.merged.bed";
AG_V6_interval="kit/SureSelect_Human_All_Exon_V6_r2/S07604514_Regions.merged.bed.intervals";
IDT_bed="kit/xGen_Exome_Research_Panel/xgen-exome-research-panel.merged.bed";
IDT_intervals="kit/xGen_Exome_Research_Panel/xgen-exome-research-panel.merged.bed.interval";
TW_Spike_bed="kit/Twist/v1.3/Twist_Exome_RefSeq_targets_hg38_CoreExomeRefSeq.merged.symbol.bed";
TW_Spike_inteval="kit/Twist/v1.3/Twist_Exome_RefSeq_targets_hg38_CoreExomeRefSeq.merged.symbol.bed.interval";

