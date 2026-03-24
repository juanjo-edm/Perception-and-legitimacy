# Perception of Insecurity and Institutional Legitimacy in Bogotá

## Overview

This project develops a computational framework to analyze the **perception of insecurity in Bogotá** by integrating official crime statistics with large-scale textual data. Using methods from **Natural Language Processing (NLP)**, **machine learning**, and **large language models (LLMs)**, the study quantifies how insecurity is represented and emotionally framed in public discourse.

The project contributes to the literature by proposing a **reproducible and scalable methodology** to measure subjective perceptions—such as fear, trust, and legitimacy—through unstructured data.

---

## Research Objectives

- Quantify the perception of insecurity using textual data  
- Extract emotional patterns from media discourse  
- Compare perceived insecurity with observed crime trends  
- Analyze institutional legitimacy through narrative structures  
- Provide a reproducible pipeline for computational social science research  

---

## Data Sources

The analysis combines two complementary sources:

### 1. Official crime data  
- High-impact theft records (2022–2025)  
- Disaggregated by locality in Bogotá  
- Source: Secretaría Distrital de Seguridad  

### 2. Textual data (Google News)  
- News articles related to crime and security  
- Collected via automated web scraping  
- Time-aligned with crime data  

---

## Methodology

### Data Collection
- Automated scraping using `RSelenium`  
- Structured queries in Google News  
- Integration with official crime datasets  

### Text Processing
- Cleaning and normalization  
- Tokenization and linguistic preprocessing  
- Named entity recognition with `spacyr`  

### Sentiment and Emotion Analysis
- Lexicon-based approach using `syuzhet`  
- NRC emotion classification  
- Theoretical framework based on Plutchik’s model  

### Modeling and Analysis
- Word co-occurrence networks  
- Structural Topic Modeling (STM)  
- Wordfish scaling model  
- Collocation analysis using `quanteda`  

### Validation
- Semantic coherence and exclusivity (STM)  
- Clustering metrics (silhouette coefficient)  
- Network topology measures (centrality, modularity)  
- Temporal consistency checks  

---

## AI Agent (RAG-based System)

The project includes an experimental AI agent designed for domain-specific analysis of news and public discourse.

- Local LLMs deployed via Ollama  
- Integration through the `ellmer` package  
- Retrieval-Augmented Generation (RAG) using `ragnar`  
- Interactive interface built with Shiny  

The system enables structured querying of the news corpus while ensuring responses are grounded in verifiable data.

---

## Reproducibility

Reproducibility is a core component of the project:

- Dependency management with `renv`  
- Integrated analysis using R Markdown  
- Version control via Git  

To restore the computational environment:

```r
renv::restore()