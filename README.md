# DenovoCNN_WDL

# DeNovoCNN

A deep learning approach to call de novo mutations (DNMs) on whole-exome (WES) and whole-genome sequencing (WGS) data. DeNovoCNN uses trio BAM/CRAM + VCF (or tab-separated list of variants) files to generate image-like genomic sequence representations and detect DNMs with high accuracy. <br>
<br>
DeNovoCNN is a combination of three models for the calling of substitution, deletion and insertion DNMs. Each of the model is a 9-layers CNN with [squeeze-and-excitation](https://arxiv.org/pdf/1709.01507.pdf) blocks. DeNovoCNN is trained on ~50k manually curated DNM and IV (inherited and non-DNM variants) sequencing data, generated using [Illumina](https://www.illumina.com/) sequencer and [Sureselect Human
All Exon V5](https://www.agilent.com/cs/library/datasheets/public/AllExondatasheet-5990-9857EN.pdf)/[Sureselect Human
All Exon V4](https://www.agilent.com/cs/library/flyers/Public/5990-9857en_lo.pdf) capture kits.  <br>
<br>
DeNovoCNN returns a tab-separated file of format:
> Chromosome | Start position | End position | Reference | Variant | DNM posterior probability | Mean coverage 

We used **DNM posterior probability >= 0.5** to create a filtered tab-separated file with the list of variants that are likely to be *de novo*.

## How does it work?

DeNovoCNN reads BAM files and iterates through potential DNM locations using the input VCF files to generate snapshots of genomic regions. It stacks trio BAM files to generate and RGB image representation which are passed into a CNN with squeeze-and-excitation blocks to classify each image as either DNM or IV (inherited variant, non-DNM).<br>
<br>

## Usage

### Docker

DeNovoCNN is available as a docker container. 

The example of DeNovoCNN usage for prediction (to use pretrained models, corresponding arguments shoud remain unchanged):
```bash
docker run \
  -v "YOUR_INPUT_DIRECTORY":"/input" \
  -v "YOUR_OUTPUT_DIRECTORY:/output" \
 registry.miracle.ac.cn/broad/denovocnn:latest \
  /app/apply_denovocnn.sh\
    --workdir=/output \
    --child-vcf=/input/<CHILD_VCF> \
    --father-vcf=/input/<FATHER_VCF> \
    --mother-vcf=/input/<MOTHER_VCF> \
    --child-bam=/input/<CHILD_BAM> \
    --father-bam=/input/<FATHER_BAM> \
    --mother-bam=/input/<MOTHER_BAM> \
    --snp-model=/app/models/snp \
    --in-model=/app/models/ins \
    --del-model=/app/models/del \
    --genome=/input/<REFERENCE_GENOME> \
    --outputo=predictions.csv
```
Parameters description and usage are described earlier in the previous section. 
